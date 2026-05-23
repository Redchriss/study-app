import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ModmailThreadDetail extends StatelessWidget {
  final String threadId;
  const ModmailThreadDetail({super.key, required this.threadId});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kModmailThread),
        variables: {'threadId': threadId},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const SizedBox(
              height: 200, child: Center(child: LoadingWidget()));
        }
        final thread = result.data?['modmailThread'];
        if (thread == null) {
          return const SizedBox(
              height: 200, child: Center(child: Text('Thread not found')));
        }
        final messages = (thread['messages'] as List?) ?? [];
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(thread['subject']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i] as Map<String, dynamic>;
                    final author = m['author'] as Map<String, dynamic>?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m['isInternal'] == true
                            ? DesignTokens.warning.withValues(alpha: 0.08)
                            : DesignTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('u/${author?['username'] ?? 'unknown'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              if (m['isInternal'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.warning
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('INTERNAL',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: DesignTokens.warning)),
                                ),
                              ],
                              const Spacer(),
                              Text(_timeAgo(m['createdAt']?.toString() ?? ''),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textTertiary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(m['body']?.toString() ?? '',
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}
