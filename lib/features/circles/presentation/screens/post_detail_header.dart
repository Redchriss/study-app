import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class PostDetailHeader extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool dark;
  const PostDetailHeader({super.key, required this.post, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostHeaderInfo(post: post, dark: dark),
        if (post['bodyHtml'] != null && post['bodyHtml'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _MarkdownBody(bodyHtml: post['bodyHtml'].toString()),
          ),
        if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(post['imageUrl'].toString(),
                  fit: BoxFit.contain, width: double.infinity,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const ShimmerBox(height: 200)),
            ),
          ),
        if (post['poll'] != null)
          PollWidget(poll: post['poll'] as Map<String, dynamic>, dark: dark),
        if (post['url'] != null && post['url'].toString().isNotEmpty)
          _LinkPreview(post: post),
      ],
    );
  }
}

class _PostHeaderInfo extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool dark;
  const _PostHeaderInfo({required this.post, required this.dark});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['flairText'] != null && post['flairText'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(post['flairText'].toString(),
                  style: TextStyle(fontSize: 10, color: DesignTokens.primary, fontWeight: FontWeight.w700)),
            ),
          Row(
            children: [
              Expanded(
                child: Text(post['title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: DesignTokens.textTertiary),
              const SizedBox(width: 4),
              Text('u/${author?['username'] ?? 'unknown'}',
                  style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.access_time_rounded, size: 12, color: DesignTokens.textTertiary),
              const SizedBox(width: 4),
              Text(_timeAgo(post['createdAt']?.toString() ?? ''),
                  style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
              if (post['isOc'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('OC', style: TextStyle(fontSize: 9, color: DesignTokens.success, fontWeight: FontWeight.w700)),
                ),
              ],
              if (post['isSpoiler'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('SPOILER', style: TextStyle(fontSize: 9, color: DesignTokens.warning, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}

class _MarkdownBody extends StatelessWidget {
  final String bodyHtml;
  const _MarkdownBody({required this.bodyHtml});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        bodyHtml.replaceAll(RegExp(r'<[^>]*>'), ''),
        style: TextStyle(fontSize: 14, height: 1.5, color: DesignTokens.textPrimary),
      ),
    );
  }
}

class PollWidget extends StatelessWidget {
  final Map<String, dynamic> poll;
  final bool dark;
  const PollWidget({super.key, required this.poll, required this.dark});

  @override
  Widget build(BuildContext context) {
    final options = (poll['options'] as List?) ?? [];
    final total = options.fold<int>(0, (sum, o) => sum + ((o['voteCount'] as num?)?.toInt() ?? 0));
    final userVote = poll['userVote'] as Map<String, dynamic>?;
    final hasVoted = userVote != null;
    final closed = poll['closesAt'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Poll${closed ? " (closed)" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...options.map((o) {
            final count = (o['voteCount'] as num?)?.toInt() ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            final isSelected = hasVoted && userVote['id'] == o['id'];
            final pollId = poll['id'].toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Mutation(
                options: MutationOptions(document: gql(kVotePoll)),
                builder: (run, _) => GestureDetector(
                  onTap: (hasVoted || closed) ? null : () => run({'pollId': pollId, 'optionId': o['id']}),
                  child: Stack(
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignTokens.primary.withValues(alpha: 0.15)
                              : dark ? DesignTokens.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            if (hasVoted || closed) ...[
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                size: 18,
                                color: isSelected ? DesignTokens.primary : DesignTokens.textTertiary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(o['text']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            if (hasVoted || closed)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('${(pct * 100).toInt()}%',
                                    style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                      if ((hasVoted || closed) && pct > 0)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct,
                              child: Container(
                                color: DesignTokens.primary.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (hasVoted || closed)
            Text('$total total votes',
                style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
        ],
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  final Map<String, dynamic> post;
  const _LinkPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final domain = post['urlDomain']?.toString() ?? '';
    final thumbnail = post['urlThumbnail']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Row(
        children: [
          if (thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(thumbnail, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          if (thumbnail.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title']?.toString() ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (domain.isNotEmpty)
                  Text(domain, style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
              ],
            ),
          ),
          Icon(Icons.open_in_new, size: 16, color: DesignTokens.textTertiary),
        ],
      ),
    );
  }
}
