import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ClassicPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const ClassicPostCard({super.key, required this.post, required this.onTap});

  @override
  State<ClassicPostCard> createState() => _ClassicPostCardState();
}

class _ClassicPostCardState extends State<ClassicPostCard> {
  bool _spoilerRevealed = false;
  bool _nsfwRevealed = false;

  Map<String, dynamic> get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final community = post['community'] as Map<String, dynamic>?;
    final author = post['author'] as Map<String, dynamic>?;
    final isRemoved = post['isRemoved'] == true;
    final isDeleted = post['isDeleted'] == true;
    final isLocked = post['isLocked'] == true;
    final isPinned = post['isPinned'] == true;
    final isSpoiler = post['isSpoiler'] == true;
    final isNsfw = post['isNsfw'] == true;
    final hasStateBadge = isRemoved || isDeleted || isLocked || isNsfw;
    final hasBlur =
        (isSpoiler && !_spoilerRevealed) || (isNsfw && !_nsfwRevealed);

    return AnimatedPress(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
              color: dark ? DesignTokens.darkBorder : DesignTokens.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left vote column
            _ClassicVoteColumn(
              postId: post['id'].toString(),
              score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
              userVote: (post['voteDirection'] as num?)?.toInt(),
              dark: dark,
            ),
            // Thumbnail
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildThumbnail(hasBlur, isSpoiler, isNsfw),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community + author
                    Row(
                      children: [
                        _ClassicCommunityAvatar(community: community),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'y/${community?['name'] ?? '?'} · u/${author?['username'] ?? '?'}',
                            style: const TextStyle(
                                fontSize: 10, color: DesignTokens.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned)
                          const Icon(Icons.push_pin_rounded,
                              size: 12, color: DesignTokens.warning),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      hasStateBadge
                          ? _stateBadge(isRemoved, isDeleted, isLocked)
                          : (post['title']?.toString() ?? ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: hasStateBadge ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Comments count
                    Row(
                      children: [
                        Icon(
                          isLocked
                              ? Icons.lock_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: isLocked
                              ? DesignTokens.warning
                              : DesignTokens.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _count(post['commentCount']),
                          style: TextStyle(
                              fontSize: 11,
                              color: isLocked
                                  ? DesignTokens.warning
                                  : DesignTokens.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool blurred, bool isSpoiler, bool isNsfw) {
    final hasImage =
        post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;

    if (!hasImage) {
      return Container(
        color: DesignTokens.surfaceVariant,
        child: const Icon(Icons.article_outlined,
            color: DesignTokens.textTertiary, size: 28),
      );
    }

    if (blurred) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Image.network(post['imageUrl'].toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (isSpoiler) _spoilerRevealed = true;
              if (isNsfw) _nsfwRevealed = true;
            }),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Icon(
                  isNsfw
                      ? Icons.warning_amber_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Image.network(post['imageUrl'].toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
              color: DesignTokens.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined,
                  color: DesignTokens.textTertiary, size: 24),
            ));
  }

  String _stateBadge(bool removed, bool deleted, bool locked) {
    if (removed) return '[Removed]';
    if (deleted) return '[Deleted]';
    if (locked) return '🔒 Locked';
    return '';
  }

  String _count(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Vote column ───────────────────────────────────────────────────────────────
class _ClassicVoteColumn extends ConsumerWidget {
  final String postId;
  final int score;
  final int? userVote;
  final bool dark;

  const _ClassicVoteColumn({
    required this.postId,
    required this.score,
    required this.dark,
    this.userVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Mutation(
      options: MutationOptions(document: gql(kVotePost)),
      builder: (runMutation, result) {
        void vote(int dir) {
          if (result?.isLoading ?? false) return;
          runMutation({'postId': postId, 'direction': dir});
        }

        final upColor =
            userVote == 1 ? DesignTokens.secondary : DesignTokens.textTertiary;
        final downColor =
            userVote == -1 ? DesignTokens.error : DesignTokens.textTertiary;
        final scoreColor = userVote == 1
            ? DesignTokens.secondary
            : userVote == -1
                ? DesignTokens.error
                : DesignTokens.textSecondary;

        return Container(
          width: 36,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusMd),
              bottomLeft: Radius.circular(DesignTokens.radiusMd),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => vote(1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 16, color: upColor),
                ),
              ),
              Text(
                _fmt(score),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: scoreColor),
              ),
              GestureDetector(
                onTap: () => vote(-1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_downward_rounded,
                      size: 16, color: downColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Community avatar ──────────────────────────────────────────────────────────
class _ClassicCommunityAvatar extends StatelessWidget {
  final Map<String, dynamic>? community;
  const _ClassicCommunityAvatar({this.community});

  @override
  Widget build(BuildContext context) {
    final icon = community?['icon']?.toString() ?? '';
    final name = community?['name']?.toString() ?? '?';
    return CircleAvatar(
      radius: 8,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      onBackgroundImageError: icon.isNotEmpty ? (_, __) {} : null,
      child: icon.isEmpty
          ? Text(name[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary))
          : null,
    );
  }
}
