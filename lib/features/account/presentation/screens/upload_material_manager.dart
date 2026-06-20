import 'dart:convert';

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

  static const _autofillContentTypes = {'pdf', 'text', 'image', 'video'};
  static const _autofillMaxFileBytes = 300000;

  String contentType = 'pdf';
  String? subjectId;
  bool saving = false;
  bool suggesting = false;
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

  /// True when there is something for the AI to read (pasted notes or a file).
  bool get canSuggestMetadata =>
      textCtrl.text.trim().isNotEmpty || selectedFile?.bytes != null;

  String _mimeForExtension(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSnack(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Opt-in AI auto-fill: infers title/subject/type from a small content slice.
  /// Suggestions are applied but stay fully editable and never block the form.
  Future<void> suggestMetadata(BuildContext context) async {
    if (suggesting) return;

    String? contentSlice;
    String? fileB64;
    String? mime;

    final text = textCtrl.text.trim();
    if (text.isNotEmpty) {
      contentSlice = text.length > 2000 ? text.substring(0, 2000) : text;
    } else if (selectedFile?.bytes != null) {
      final bytes = selectedFile!.bytes!;
      final slice = bytes.length > _autofillMaxFileBytes
          ? bytes.sublist(0, _autofillMaxFileBytes)
          : bytes;
      fileB64 = base64Encode(slice);
      mime = _mimeForExtension(selectedFile!.extension);
    }

    if ((contentSlice == null || contentSlice.isEmpty) && fileB64 == null) {
      _showSnack(
        context,
        'Add some notes or pick a file first so AI has something to read.',
        DesignTokens.error,
      );
      return;
    }

    _setState(() => suggesting = true);
    try {
      final client = _ref.read(graphqlClientProvider);
      final result = await client.mutate(
        MutationOptions(
          document: gql(kSuggestMaterialMetadata),
          variables: {
            'contentSlice': contentSlice,
            'fileB64': fileB64,
            'mime': mime,
          },
        ),
      );
      if (!_isMounted()) return;
      if (result.hasException) {
        _showSnack(
          context,
          graphQLErrorMessage(result.exception, 'AI auto-fill failed.'),
          DesignTokens.error,
        );
        return;
      }
      final payload =
          result.data?['suggestMaterialMetadata'] as Map<String, dynamic>?;
      if (payload == null || payload['success'] != true) {
        final errors = (payload?['errors'] as List?)?.cast<String>() ??
            const <String>[];
        _showSnack(
          context,
          errors.isNotEmpty
              ? errors.first
              : 'AI could not suggest details. Fill them in manually.',
          DesignTokens.error,
        );
        return;
      }
      final suggestion = payload['suggestion'] as Map<String, dynamic>?;
      if (suggestion == null) {
        _showSnack(
          context,
          'AI had nothing confident to suggest — fill the form manually.',
          DesignTokens.warning,
        );
        return;
      }
      _applySuggestion(suggestion);
      _showSnack(
        context,
        'Filled with AI. Review and edit before submitting.',
        DesignTokens.success,
      );
    } finally {
      if (_isMounted()) _setState(() => suggesting = false);
    }
  }

  void _applySuggestion(Map<String, dynamic> suggestion) {
    final title = suggestion['title']?.toString();
    final suggestedSubjectId = suggestion['subjectId']?.toString();
    final suggestedType = suggestion['contentType']?.toString();
    _setState(() {
      if (title != null && title.isNotEmpty) {
        titleCtrl.text = title;
      }
      if (suggestedSubjectId != null && _subjectExists(suggestedSubjectId)) {
        subjectId = suggestedSubjectId;
      }
      if (suggestedType != null &&
          _autofillContentTypes.contains(suggestedType)) {
        contentType = suggestedType;
      }
    });
  }

  bool _subjectExists(String id) {
    final list = subjects;
    if (list == null) return false;
    return list.any((s) => s['id']?.toString() == id);
  }

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
