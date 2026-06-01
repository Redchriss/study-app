import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class CommunityCardWidget extends StatefulWidget {
  final Map<String, dynamic> community;
  final bool compact;

  const CommunityCardWidget({
    super.key,
    required this.community,
    this.compact = false,
  });

  @override
  State<CommunityCardWidget> createState() => _CommunityCardWidgetState();
}

class _CommunityCardWidgetState extends State<CommunityCardWidget> {
  bool _joining = false;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.community;
    final name = c['name']?.toString() ?? '';
    final displayName = c['displayName']?.toString() ?? name;
    final description = c['description']?.toString() ?? '';
    final memberCount = (c['memberCount'] as num?)?.toInt() ?? 0;
    final postCount = (c['postCount'] as num?)?.toInt() ?? 0;
    final icon = c['icon']?.toString() ?? '';

    if (widget.compact) {
      return GestureDetector(
        onTap: () => context.push('/y/$name'),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: DesignTokens.border.withAlpha((0.3 * 255).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        DesignTokens.primary.withAlpha((0.1 * 255).round()),
                    backgroundImage:
                        icon.isNotEmpty ? NetworkImage(icon) : null,
                    child: icon.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: DesignTokens.primary,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const Spacer(),
                  Text('y/$name',
                      style: const TextStyle(
                          fontSize: 10,
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (description.isNotEmpty)
                Text(description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: DesignTokens.textSecondary)),
              const Spacer(),
              Row(
                children: [
                  Text('${_fmt(memberCount)} members',
                      style: const TextStyle(
                          fontSize: 10, color: DesignTokens.textTertiary)),
                  const SizedBox(width: 4),
                  const Text('•',
                      style: TextStyle(
                          fontSize: 10, color: DesignTokens.textTertiary)),
                  const SizedBox(width: 4),
                  Text('${_fmt(postCount)} posts',
                      style: const TextStyle(
                          fontSize: 10, color: DesignTokens.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: DesignTokens.border.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                DesignTokens.primary.withAlpha((0.1 * 255).round()),
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
            child: GestureDetector(
              onTap: () => context.push('/y/$name'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('y/$name • ${_fmt(memberCount)} members',
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
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: Mutation(
              options: MutationOptions(document: gql(kJoinCommunity)),
              builder: (run, result) {
                return OutlinedButton(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
