import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class MaterialUploadResult {
  const MaterialUploadResult({
    required this.success,
    this.message,
    this.errors = const <String>[],
    this.slug,
    this.aiReadiness,
    this.isApproved,
    this.title,
    this.contentType,
    this.subjectName,
  });

  final bool success;
  final String? message;
  final List<String> errors;
  final String? slug;
  final String? aiReadiness;
  final bool? isApproved;
  final String? title;
  final String? contentType;
  final String? subjectName;
}

class MaterialUploadService {
  Future<MaterialUploadResult> upload({
    required String title,
    required String subjectId,
    required String contentType,
    String? description,
    String? contentText,
    String? youtubeUrl,
    PlatformFile? file,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      return const MaterialUploadResult(
        success: false,
        errors: <String>['You need to sign in again before uploading.'],
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiUrl}/materials/api/upload/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['subject'] = subjectId;
    request.fields['content_type'] = contentType;
    if (description != null && description.trim().isNotEmpty) {
      request.fields['description'] = description.trim();
    }
    if (contentText != null && contentText.trim().isNotEmpty) {
      request.fields['content_text'] = contentText.trim();
    }
    if (youtubeUrl != null && youtubeUrl.trim().isNotEmpty) {
      request.fields['youtube_url'] = youtubeUrl.trim();
    }
    if (file != null) {
      if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
      } else if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      }
    }

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = body.isEmpty ? const <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
      final errors = ((decoded['errors'] as List?) ?? const <dynamic>[])
          .map((error) => error.toString())
          .toList();

      if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
        return MaterialUploadResult(
          success: false,
          message: decoded['message']?.toString(),
          errors: errors.isNotEmpty ? errors : <String>['Upload failed. Please try again.'],
        );
      }

      return MaterialUploadResult(
        success: true,
        message: decoded['message']?.toString(),
        slug: (decoded['material'] as Map?)?['slug']?.toString(),
        aiReadiness: decoded['aiReadiness']?.toString(),
        isApproved: (decoded['material'] as Map?)?['isApproved'] == true,
        title: (decoded['material'] as Map?)?['title']?.toString(),
        contentType: (decoded['material'] as Map?)?['contentType']?.toString(),
        subjectName: (decoded['material'] as Map?)?['subjectName']?.toString(),
      );
    } catch (_) {
      return const MaterialUploadResult(
        success: false,
        errors: <String>['Network error. Check your connection and try again.'],
      );
    }
  }
}
