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
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );
    if (!_isMounted()) return;
    if (result.hasException) {
      _setState(() {
        loadingSubjects = false;
        subjectLoadError = graphQLErrorMessage(result.exception, 'Could not load subjects.');
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

  String levelLabel(BuildContext context) {
    final level = _ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    switch (level) {
      case 'primary': return 'Primary';
      case 'tertiary': return 'Tertiary / University';
      default: return 'Secondary';
    }
  }

  String titlePlaceholder() {
    final level = _ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    switch (contentType) {
      case 'pdf':
        if (level == 'primary') return 'e.g. Standard 7 Maths – Fractions';
        if (level == 'tertiary') return 'e.g. UNIMA Physics 201 – Thermodynamics Notes';
        return 'e.g. Form 3 Biology – Respiration';
      case 'image':
        if (level == 'primary') return 'e.g. Diagram – Water Cycle';
        if (level == 'tertiary') return 'e.g. Anatomy Diagram – Digestive System';
        return 'e.g. MSCE Geography – Rainfall Map';
      case 'video':
        if (level == 'primary') return 'e.g. English Lesson – Parts of Speech';
        if (level == 'tertiary') return 'e.g. Organic Chemistry – Alkene Reactions';
        return 'e.g. MSCE Mathematics – Differentiation';
      case 'text':
        if (level == 'primary') return 'e.g. Science Summary – Living Things';
        if (level == 'tertiary') return 'e.g. Law Notes – Constitutional Law';
        return 'e.g. History Notes – Colonial Malawi';
      default:
        return 'e.g. Form 3 Biology Notes – Respiration';
    }
  }

  String descPlaceholder() {
    final level = _ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    if (level == 'primary') return 'What topic does this cover? What standard is it for?';
    if (level == 'tertiary') return 'What course, year, and topics are covered in this material?';
    return 'What form and subject is this for? What topics does it cover?';
  }

  String primaryHint() {
    switch (contentType) {
      case 'pdf': return 'Upload revision booklets, topic handouts, or scanned notes that students can read in-app.';
      case 'image': return 'Upload diagrams, worked examples, maps, or annotated pages students can zoom into.';
      case 'video': return 'Use a YouTube lesson so students can watch in-app and the AI can reuse transcripts when available.';
      case 'text': return 'Paste notes directly or attach a readable file if you already have one.';
      default: return '';
    }
  }

  String fileButtonLabel() {
    switch (contentType) {
      case 'pdf': return 'Choose PDF';
      case 'image': return 'Choose Image';
      case 'text': return 'Attach File';
      default: return 'Choose File';
    }
  }

  List<String> allowedExtensions() {
    switch (contentType) {
      case 'pdf': return const ['pdf'];
      case 'image': return const ['png', 'jpg', 'jpeg', 'gif', 'webp'];
      case 'text': return const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'];
      default: return const [];
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions(),
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
    if (requiresFile && selectedFile == null) errors.add('Choose a file for this material.');
    if (contentType == 'video' && youtubeCtrl.text.trim().isEmpty) {
      errors.add('Paste a YouTube link for the lesson.');
    }
    if (contentType == 'text' && textCtrl.text.trim().isEmpty && selectedFile == null) {
      errors.add('Paste notes or attach a file for this text material.');
    }
    return errors;
  }

  Future<void> submit(BuildContext context) async {
    final errors = validateForm();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first), backgroundColor: DesignTokens.error),
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
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.isNotEmpty ? result.errors.first : (result.message ?? 'Upload failed')),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Material submitted for review'),
        backgroundColor: DesignTokens.success,
      ),
    );
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
