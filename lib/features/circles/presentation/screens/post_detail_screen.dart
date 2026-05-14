import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String circleSlug; final String postSlug;
  const PostDetailScreen({super.key, required this.circleSlug, required this.postSlug});
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;
  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _submitComment(String postId, VoidCallback? refetch) async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final result = await ref.read(graphqlClientProvider).mutate(MutationOptions(
        document: gql(kAddComment),
        variables: {'postId': postId, 'content': content},
      ));
      if (!mounted) return;
      final payload = result.data?['addComment'];
      if (result.hasException || payload?['success'] != true) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            (payload?['errors'] as List?)?.firstOrNull?.toString() ??
            'Could not add comment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
        return;
      }
      _commentCtrl.clear();
      refetch?.call();
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(kPostDetail), variables: {'circleSlug': widget.circleSlug, 'postSlug': widget.postSlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final post = result.data?['circlePost'];
        if (post == null) return const Scaffold(body: Center(child: Text('Post not found')));
        return Scaffold(
          appBar: AppBar(title: Text(post['title'] ?? ''), centerTitle: true),
          body: Column(children: [
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Chip(label: Text(post['postType'] ?? 'discussion', style: const TextStyle(fontSize: 11))),
                    const Spacer(),
                    IconButton(
                      icon: Icon(post['userVote'] == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: post['userVote'] == 'up' ? DesignTokens.primary : null),
                      onPressed: () { _vote(post['id'], 'up', refetch); },
                    ),
                    Text('${post['score'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: Icon(post['userVote'] == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined, size: 20, color: post['userVote'] == 'down' ? DesignTokens.error : null),
                      onPressed: () { _vote(post['id'], 'down', refetch); },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 20, color: DesignTokens.info),
                      tooltip: 'Ask AI to reply',
                      onPressed: () async {
                        final client = ref.read(graphqlClientProvider);
                        final content = '${post['title'] ?? ''}\n${post['body'] ?? ''}';
                        final result = await client.mutate(MutationOptions(
                          document: gql(kAskAiOnPost),
                          variables: {'postId': post['id'], 'postContent': content},
                        ));
                        if (context.mounted) {
                          final message = result.data?['askAiOnPost']?['reply'] ??
                              result.exception?.graphqlErrors.firstOrNull?.message ??
                              'AI replied!';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                          refetch?.call();
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(post['body'] ?? ''),
                  if (post['imageUrl'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      child: Image.network(post['imageUrl'], width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('Posted by ${post['author']?['username'] ?? ''}', style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
                ])),
                const SizedBox(height: DesignTokens.spMd),
                SectionHeader(title: 'Comments (${post['commentCount'] ?? 0})'),
                const SizedBox(height: DesignTokens.spSm),
                Query(
                  options: QueryOptions(document: gql(kPostComments), variables: {'postId': post['id']}),
                  builder: (cResult, {fetchMore, refetch}) {
                    if (cResult.isLoading) return const Center(child: CircularProgressIndicator());
                    final comments = (cResult.data?['postComments'] as List?) ?? [];
                    if (comments.isEmpty) return const Text('No comments yet', style: TextStyle(color: DesignTokens.textSecondary));
                    return Column(children: comments.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: DesignTokens.spXs),
                      padding: const EdgeInsets.all(DesignTokens.spMd),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                        border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(c['author']?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (c['isAnswer'] == true) ...[const SizedBox(width: 6), const Icon(Icons.check_circle, size: 14, color: DesignTokens.success)],
                        ]),
                        const SizedBox(height: 4), Text(c['body'] ?? ''),
                        if (c['replies'] != null && (c['replies'] as List).isNotEmpty) ...[
                          const Divider(height: DesignTokens.spMd),
                          ...(c['replies'] as List).map((r) => Padding(
                            padding: const EdgeInsets.only(left: DesignTokens.spMd, top: DesignTokens.spXs),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['author']?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(r['body'] ?? ''),
                            ]),
                          )),
                        ],
                      ]),
                    )).toList());
                  },
                ),
              ]),
            )),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spSm),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...', isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  )),
                  const SizedBox(width: 8),
                  AnimatedPress(
                    onTap: () => _submitComment(post['id'], refetch),
                    child: Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                      child: _sendingComment
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  void _vote(String postId, String direction, dynamic refetch) {
    ref.read(graphqlClientProvider).mutate(MutationOptions(
      document: gql(kVotePost), variables: {'postId': postId, 'direction': direction},
    )).then((_) {
      if (mounted) {
        refetch?.call();
      }
    });
  }
}
