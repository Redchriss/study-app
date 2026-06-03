import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/study_progress_store.dart';
import 'material_reader_models.dart';

class ReaderServiceResult<T> {
  const ReaderServiceResult({
    required this.success,
    this.data,
    this.message,
    this.errors = const <String>[],
  });
  final bool success;
  final T? data;
  final String? message;
  final List<String> errors;
}

class MaterialReaderService {
  static const _pageProgressPrefix = 'reader_page_';
  static const _textProgressPrefix = 'reader_text_page_';
  final _progressStore = StudyProgressStore();
  String _errorMessage(QueryResult result,
      [String fallback = 'Something went wrong.']) {
    return graphQLErrorMessage(result.exception, fallback);
  }

  Future<String?> cachePdf(String url, String slug) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reader_$slug.pdf');
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<int> loadSavedPage(String slug, {bool textMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        textMode ? '$_textProgressPrefix$slug' : '$_pageProgressPrefix$slug';
    return prefs.getInt(key) ?? 0;
  }

  Future<void> savePage(String slug, int page, {bool textMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        textMode ? '$_textProgressPrefix$slug' : '$_pageProgressPrefix$slug';
    await prefs.setInt(key, page);
  }

  Future<void> trackProgress({
    required BuildContext context,
    required String slug,
    required String title,
    required String subjectName,
    required String contentType,
    required int currentUnit,
    required int totalUnits,
    String? lastPositionLabel,
  }) async {
    final client = GraphQLProvider.of(context).value;
    await _progressStore.saveMaterial(
      slug: slug,
      title: title,
      subjectName: subjectName,
      contentType: contentType,
      currentUnit: currentUnit,
      totalUnits: totalUnits,
    );
    try {
      await client.mutate(
        MutationOptions(
          document: gql(kTrackMaterialProgress),
          variables: {
            'materialSlug': slug,
            'currentUnit': currentUnit,
            'totalUnits': totalUnits,
            'lastPositionLabel': lastPositionLabel,
          },
        ),
      );
    } catch (_) {}
  }

  Future<ReaderServiceResult<void>> saveAnnotation({
    required BuildContext context,
    required String materialSlug,
    required ReaderStudySelection selection,
    required String noteText,
    required String color,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.mutate(
        MutationOptions(
          document: gql(kSaveMaterialAnnotation),
          variables: {
            'materialSlug': materialSlug,
            'unitIndex': selection.unitIndex,
            'anchorLabel': selection.anchorLabel,
            'selectedText': selection.selectedText,
            'noteText': noteText.trim(),
            'color': color,
          },
        ),
      );
      final payload = result.data?['saveMaterialAnnotation'];
      if (result.hasException || payload?['success'] != true) {
        final message =
            (payload?['errors'] as List?)?.firstOrNull?.toString() ??
                _errorMessage(result, 'Could not save annotation.');
        return ReaderServiceResult<void>(
            success: false, errors: <String>[message], message: message);
      }
      return const ReaderServiceResult<void>(success: true);
    } catch (_) {
      return const ReaderServiceResult<void>(
        success: false,
        errors: <String>['Could not save annotation.'],
      );
    }
  }

  Future<ReaderServiceResult<void>> deleteAnnotation({
    required BuildContext context,
    required String annotationId,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.mutate(
        MutationOptions(
          document: gql(kDeleteMaterialAnnotation),
          variables: {'annotationId': annotationId},
        ),
      );
      final payload = result.data?['deleteMaterialAnnotation'];
      if (result.hasException || payload?['success'] != true) {
        final message =
            (payload?['errors'] as List?)?.firstOrNull?.toString() ??
                _errorMessage(result, 'Could not delete annotation.');
        return ReaderServiceResult<void>(
            success: false, errors: <String>[message], message: message);
      }
      return const ReaderServiceResult<void>(success: true);
    } catch (_) {
      return const ReaderServiceResult<void>(
        success: false,
        errors: <String>['Could not delete annotation.'],
      );
    }
  }

  Future<ReaderServiceResult<void>> requestAiTask({
    required BuildContext context,
    required String materialId,
    required String taskType,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.mutate(
        MutationOptions(
          document: gql(kRequestAiTask),
          variables: {'materialId': materialId, 'taskType': taskType},
        ),
      );
      final payload = result.data?['requestAiTask'];
      if (result.hasException || payload?['success'] != true) {
        final message =
            (payload?['errors'] as List?)?.firstOrNull?.toString() ??
                _errorMessage(result, 'AI request failed.');
        return ReaderServiceResult<void>(
            success: false, errors: <String>[message], message: message);
      }
      return ReaderServiceResult<void>(
        success: true,
        message:
            'AI ${taskType.toLowerCase()} started. It will appear when ready.',
      );
    } catch (_) {
      return const ReaderServiceResult<void>(
        success: false,
        errors: <String>['AI request failed.'],
      );
    }
  }

  Future<ReaderServiceResult<String>> askAi({
    required BuildContext context,
    required String materialId,
    required String message,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      final sessionResult = await client.mutate(
        MutationOptions(
          document: gql(kCreateReaderChatSession),
          variables: {'materialId': materialId},
        ),
      );
      final sessionId = sessionResult.data?['createChatSession']?['session']
              ?['id']
          ?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        return const ReaderServiceResult<String>(
          success: false,
          errors: <String>['Could not open AI session right now.'],
        );
      }
      final response = await client.mutate(
        MutationOptions(
          document: gql(kSendReaderAiMessage),
          variables: {
            'sessionId': sessionId,
            'content': message,
            'materialId': materialId,
          },
        ),
      );
      final reply =
          response.data?['sendMessage']?['message']?['messageText']?.toString();
      final payloadError = response.data?['sendMessage']?['error']?.toString();
      if (response.hasException || reply == null || reply.isEmpty) {
        final message = payloadError ??
            _errorMessage(response, 'AI could not answer right now.');
        return ReaderServiceResult<String>(
            success: false, errors: <String>[message], message: message);
      }
      return ReaderServiceResult<String>(success: true, data: reply);
    } catch (_) {
      return const ReaderServiceResult<String>(
        success: false,
        errors: <String>['AI could not answer right now.'],
      );
    }
  }
}
