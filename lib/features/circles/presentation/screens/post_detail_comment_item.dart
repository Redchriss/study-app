import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PostDetailCommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool dark;

  const PostDetailCommentItem({
    super.key,
    required this.comment,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: dark
                ? Colors.transparent
                : Colors.grey.shade200),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: DesignTokens.primary
                    .withValues(alpha: 0.2),
                child: Text(
                  comment['author']?['username']
                          ?.toString()
                          .substring(0, 1)
                          .toUpperCase() ??
                      '?',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                  comment['author']?['username'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              if (comment['isAnswer'] == true) ...[
                const SizedBox(width: 6),
                const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: DesignTokens.success)
              ],
            ]),
            const SizedBox(height: 8),
            Text(comment['body'] ?? '',
                style: const TextStyle(
                    fontSize: 14, height: 1.4)),
            if (comment['replies'] != null &&
                (comment['replies'] as List)
                    .isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: DesignTokens.primary
                              .withValues(alpha: 0.2),
                          width: 2)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children:
                      (comment['replies'] as List)
                          .map((r) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                        top: 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                          r['author']?['username'] ??
                                              '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: DesignTokens
                                                  .textSecondary)),
                                      const SizedBox(
                                          height: 4),
                                      Text(
                                          r['body'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4)),
                                    ]),
                              ))
                          .toList(),
                ),
              ),
            ],
          ]),
    );
  }
}
