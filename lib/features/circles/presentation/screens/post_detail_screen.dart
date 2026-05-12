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
  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(r'''
        query PD($circleSlug: String!, $postSlug: String!) {
          circlePost(circleSlug: $circleSlug, postSlug: $postSlug) {
            id title body upvoteCount downvoteCount commentCount postType isSolved score userVote
            author { username } createdAt
          }
        }
      '''), variables: {'circleSlug': widget.circleSlug, 'postSlug': widget.postSlug}),
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
                  ]),
                  const SizedBox(height: 8),
                  Text(post['body'] ?? ''),
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
              child: Mutation(options: MutationOptions(document: gql(kAddComment)),
                builder: (run, _) => Container(
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
                      onTap: () {
                        if (_commentCtrl.text.trim().isEmpty) return;
                        run({'postId': post['id'], 'content': _commentCtrl.text.trim()});
                        _commentCtrl.clear();
                      },
                      child: Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  void _vote(String postId, String direction, dynamic refetch) {
    ref.read(graphqlClientProvider.future).then((client) => client.mutate(MutationOptions(
      document: gql(kVotePost), variables: {'postId': postId, 'direction': direction},
    )).then((_) => refetch?.call()));
  }
}
