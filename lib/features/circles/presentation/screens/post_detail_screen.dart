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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? DesignTokens.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (post['postType'] ?? 'discussion').toString().toUpperCase(), 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DesignTokens.primary)
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(post['userVote'] == 'up' ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, size: 18, color: post['userVote'] == 'up' ? DesignTokens.primary : DesignTokens.textSecondary),
                            onPressed: () { _vote(post['id'], 'up', refetch); },
                          ),
                          Text('${post['score'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(post['userVote'] == 'down' ? Icons.thumb_down_rounded : Icons.thumb_down_outlined, size: 18, color: post['userVote'] == 'down' ? DesignTokens.error : DesignTokens.textSecondary),
                            onPressed: () { _vote(post['id'], 'down', refetch); },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 22, color: DesignTokens.info),
                      tooltip: 'Ask AI to reply',
                      style: IconButton.styleFrom(backgroundColor: DesignTokens.info.withValues(alpha: 0.1)),
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
                  const SizedBox(height: 16),
                  Text(
                    post['body'] ?? '', 
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  if (post['imageUrl'] != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(post['imageUrl'], width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
                        child: Text(
                          post['author']?['username']?.toString().substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DesignTokens.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Posted by ${post['author']?['username'] ?? 'Anonymous'}', style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ])),
                const SizedBox(height: 24),
                SectionHeader(title: 'Comments (${post['commentCount'] ?? 0})'),
                const SizedBox(height: 16),
                Query(
                  options: QueryOptions(document: gql(kPostComments), variables: {'postId': post['id']}),
                  builder: (cResult, {fetchMore, refetch}) {
                    if (cResult.isLoading) return const Center(child: CircularProgressIndicator());
                    final comments = (cResult.data?['postComments'] as List?) ?? [];
                    if (comments.isEmpty) return const Text('No comments yet. Be the first!', style: TextStyle(color: DesignTokens.textSecondary));
                    return Column(children: comments.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: dark ? Colors.transparent : Colors.grey.shade200),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
                            child: Text(
                              c['author']?['username']?.toString().substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DesignTokens.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c['author']?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          if (c['isAnswer'] == true) ...[const SizedBox(width: 6), const Icon(Icons.check_circle_rounded, size: 16, color: DesignTokens.success)],
                        ]),
                        const SizedBox(height: 8), 
                        Text(c['body'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                        if (c['replies'] != null && (c['replies'] as List).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: DesignTokens.primary.withValues(alpha: 0.2), width: 2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: (c['replies'] as List).map((r) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r['author']?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: DesignTokens.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(r['body'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                                ]),
                              )).toList(),
                            ),
                          ),
                        ],
                      ]),
                    )).toList());
                  },
                ),
              ]),
            )),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkSurface : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: DesignTokens.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sendingComment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _submitComment(post['id'], refetch),
                  ),
                ),
              ]),
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
