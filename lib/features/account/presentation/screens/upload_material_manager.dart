import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/material_upload_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/upload_success_sheet.dart';
import 'upload_material_labels.dart';

class UploadMaterialManager {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final textCtrl = TextEditingController();
  final youtubeCtrl = TextEditingController();
  final uploadService = MaterialUploadService();

  String contentType = 'pdf';
  String? subjectId;
  bool saving = false;
  bool loadingSubjects = true;
  String? subjectLoadError;
  PlatformFile? selectedFile;
  List? subjects;
  String educationLevel = 'secondary';

  late WidgetRef _ref;
  late void Function(VoidCallback) _setState;
  late bool Function() _isMounted;

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required bool Function() isMounted,
  }) {
    _ref = ref;
    _setState = setState;
    _isMounted = isMounted;
  }

  void init() => loadSubjects();

  void updateEducationLevel(String? level) {
    educationLevel = level ?? 'secondary';
  }

  Future<void> loadSubjects() async {
    final auth = _ref.read(authProvider);
    final educationLevel = auth.user?['profile']?['educationLevel']?.toString();
    if (educationLevel == null || educationLevel.isEmpty) {
      _setState(() {
        loadingSubjects = false;
        subjectLoadError =
            'Complete your profile education level before uploading materials.';
      });
      return;
    }
    _setState(() {
      loadingSubjects = true;
      subjectLoadError = null;
    });
    final client = _ref.read(graphqlClientProvider);
    final result = await client.query(
      QueryOptions(
        document: gql(kSubjects),
        variables: {'educationLevel': educationLevel},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
    );
    if (!_isMounted()) return;
    if (result.hasException) {
      _setState(() {
        loadingSubjects = false;
        subjectLoadError =
            graphQLErrorMessage(result.exception, 'Could not load subjects.');
      });
      return;
    }
    _setState(() {
      subjects = (result.data?['subjects'] as List?) ?? [];
      loadingSubjects = false;
    });
  }

  bool get requiresFile => contentType == 'pdf' || contentType == 'image';
  bool get supportsOptionalFile => contentType == 'text';

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: UploadMaterialLabels.allowedExtensions(contentType),
    );
    if (!_isMounted() || result == null || result.files.isEmpty) return;
    _setState(() => selectedFile = result.files.single);
  }

  void changeType(String nextType) {
    if (contentType == nextType) return;
    _setState(() {
      contentType = nextType;
      selectedFile = null;
      textCtrl.clear();
      youtubeCtrl.clear();
    });
  }

  List<String> validateForm() {
    final errors = <String>[];
    if (titleCtrl.text.trim().isEmpty) errors.add('Add a clear title.');
    if (subjectId == null) errors.add('Pick a subject.');
    if (requiresFile && selectedFile == null) {
      errors.add('Choose a file for this material.');
    }
    if (contentType == 'video' && youtubeCtrl.text.trim().isEmpty) {
      errors.add('Paste a YouTube link for the lesson.');
    }
    if (contentType == 'text' &&
        textCtrl.text.trim().isEmpty &&
        selectedFile == null) {
      errors.add('Paste notes or attach a file for this text material.');
    }
    return errors;
  }

  Future<void> submit(BuildContext context) async {
    final errors = validateForm();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errors.first), backgroundColor: DesignTokens.error),
      );
      return;
    }
    _setState(() => saving = true);
    final result = await uploadService.upload(
      title: titleCtrl.text.trim(),
      subjectId: subjectId!,
      contentType: contentType,
      description: descCtrl.text.trim(),
      contentText: textCtrl.text.trim(),
      youtubeUrl: youtubeCtrl.text.trim(),
      file: selectedFile,
    );
    if (!_isMounted()) return;
    _setState(() => saving = false);
    if (!context.mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.isNotEmpty
              ? result.errors.first
              : (result.message ?? 'Upload failed')),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Material submitted for review'),
        backgroundColor: DesignTokens.success,
      ),
    );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UploadSuccessSheet(result: result),
    );
    if (_isMounted()) {
      titleCtrl.clear();
      descCtrl.clear();
      textCtrl.clear();
      youtubeCtrl.clear();
      _setState(() => selectedFile = null);
    }
  }

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    textCtrl.dispose();
    youtubeCtrl.dispose();
  }
}
