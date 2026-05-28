import 'package:flutter/material.dart';

import '../../../../core/services/material_cache_service.dart';
import '../../../../core/widgets/widgets.dart';
import 'material_reader_models.dart';
import 'reader_cache_banner.dart';
import 'reader_chrome.dart';

class MaterialReaderErrorHandler extends StatelessWidget {
  const MaterialReaderErrorHandler({
    super.key,
    required this.slug,
    required this.errorMessage,
    required this.onRetry,
    required this.cache,
    required this.onCachedData,
  });

  final String slug;
  final String errorMessage;
  final VoidCallback? onRetry;
  final MaterialCacheService cache;
  final Widget Function(ReaderMaterialData) onCachedData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: cache.loadMaterial(slug),
      builder: (context, snapshot) {
        final cached = snapshot.data;
        if (cached == null) {
          return ReaderScaffold(
            title: 'Study mode',
            child: ErrorState(
              message: errorMessage,
              onRetry: onRetry,
            ),
          );
        }
        return Stack(
          children: [
            onCachedData(ReaderMaterialData.fromMap(slug, cached)),
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: ReaderCacheBanner(),
            ),
          ],
        );
      },
    );
  }
}
