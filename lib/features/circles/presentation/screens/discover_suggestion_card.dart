import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class DiscoverSuggestionCard extends StatefulWidget {
  final Map<String, dynamic> community;
  const DiscoverSuggestionCard({super.key, required this.community});

  @override
  State<DiscoverSuggestionCard> createState() => _DiscoverSuggestionCardState();
}

class _DiscoverSuggestionCardState extends State<DiscoverSuggestionCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.community;
    final name = c['name']?.toString() ?? '';
    final displayName = c['displayName']?.toString() ?? name;
    final memberCount = (c['memberCount'] as num?)?.toInt() ?? 0;
    final description = c['description']?.toString() ?? '';
    final icon = c['icon']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
            backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
            child: icon.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: DesignTokens.primary,
                        fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('y/$name • ${_formatCount(memberCount)} members',
                    style: const TextStyle(
                        fontSize: 11, color: DesignTokens.textTertiary)),
                if (description.isNotEmpty)
                  Text(description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Mutation(
            options: MutationOptions(document: gql(kJoinCommunity)),
            builder: (run, result) {
              return SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: _joining
                      ? null
                      : () {
                          setState(() => _joining = true);
                          run({'slug': name});
                        },
                  child: _joining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Join', style: TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
