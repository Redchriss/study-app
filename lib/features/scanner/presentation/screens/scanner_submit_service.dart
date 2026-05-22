import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

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
  }) async {
    onSolvingStart();
    try {
      final client = ref.read(graphqlClientProvider);
      final bytes = await image.readAsBytes();
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
      final result = await client.mutate(
        MutationOptions(
          document: gql(kSubmitScanSession),
          variables: {
            'imageBase64': b64,
            'fileName': image.path.split('/').last,
            'subject': subject?.trim() ?? '',
            'educationLevel': educationLevel ?? 'secondary',
            'examType': examType.trim(),
            'year': int.tryParse(year),
          },
        ),
      );
      if (!context.mounted) return;
      onSolvingEnd();
      if (result.hasException || result.data?['submitScanSession'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.exception?.graphqlErrors.firstOrNull?.message ??
                'Failed to solve'),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      final data = result.data!['submitScanSession'];
      if (data['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                (data['errors'] as List?)?.firstOrNull?.toString() ?? 'Failed'),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      if (!context.mounted) return;
      context.push('/scanner/results',
          extra: {'solutions': data['session']?['solutions'] ?? []});
    } catch (e) {
      if (context.mounted) {
        onSolvingEnd();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }
}
