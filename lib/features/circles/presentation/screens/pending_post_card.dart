import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/pending_posts_provider.dart';

class PendingPostCard extends StatelessWidget {
  final PendingEntry entry;
  const PendingPostCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSubmitting = entry.status == PendingStatus.submitting;
    final hasFailed = entry.status == PendingStatus.failed;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final post = entry.data;
    return Opacity(
      // Pending posts read as slightly faded until they're confirmed.
      opacity: hasFailed ? 1 : 0.75,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: hasFailed
            ? DesignTokens.signatureSurface(dark).copyWith(
                border: Border.all(
                    color: DesignTokens.error.withValues(alpha: 0.5)),
              )
            : DesignTokens.signatureSurface(dark),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSubmitting)
              const SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(),
              ),
            if (hasFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: DesignTokens.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(entry.error ?? 'Post failed',
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.error)),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                Expanded(
                  child: Text(post['title']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            if (post['body'] != null && post['body'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(post['body'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: DesignTokens.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
