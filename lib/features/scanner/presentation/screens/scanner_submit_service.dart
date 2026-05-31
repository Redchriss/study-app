import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/scanner_stream_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';

Uint8List _readFileBytes(String path) {
  return File(path).readAsBytesSync();
}

class ScannerSubmitService {
  static Future<void> submit({
    required WidgetRef ref,
    required File image,
    required String? subject,
    required String? educationLevel,
    required String examType,
    required String year,
    required BuildContext context,
    required VoidCallback onSolvingStart,
    required VoidCallback onSolvingEnd,
    required void Function(String) onProgress,
  }) async {
    onSolvingStart();
    final token = await SecureStorage.getToken();
    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in again.'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
      onSolvingEnd();
      return;
    }

    try {
      final bytes = await compute(_readFileBytes, image.path);
      if (bytes.length > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large (max 5MB)'),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
        onSolvingEnd();
        return;
      }
      final b64 = base64Encode(bytes);

      final service = ScannerStreamService();
      final result = await service.send(
        imageBase64: b64,
        fileName: image.path.split('/').last,
        subject: subject,
        educationLevel: educationLevel,
        examType: examType,
        year: year,
        token: token,
        onProgress: onProgress,
        onError: (msg) {
          if (context.mounted) {
            onSolvingEnd();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: DesignTokens.error,
              ),
            );
          }
        },
      );

      if (!context.mounted) return;
      onSolvingEnd();

      if (result == null) return;

      final solutions = result['solutions'] as List? ?? [];
      if (!context.mounted) return;
      context.push('/scanner/results', extra: {'solutions': solutions});
    } catch (e) {
      HiveService.enqueueScanSubmission({
        'imagePath': image.path,
        'subject': subject,
        'educationLevel': educationLevel,
        'examType': examType,
        'year': year,
      });
      if (context.mounted) {
        onSolvingEnd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission saved — will retry when connected'),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
    }
  }
}
