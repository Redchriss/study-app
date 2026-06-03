import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_services.dart';

void showReaderResultSnackBar(BuildContext context, ReaderServiceResult result,
    String onSuccess, String onFail) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.success ? onSuccess : (result.message ?? onFail)),
      backgroundColor:
          result.success ? DesignTokens.success : DesignTokens.error,
    ),
  );
}

void showReaderErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: DesignTokens.error,
    ),
  );
}
