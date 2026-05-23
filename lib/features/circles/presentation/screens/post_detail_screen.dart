import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'post_detail_header.dart';
import 'post_detail_comments.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String communitySlug;
  final String postSlug;
  const PostDetailScreen({
    super.key,
    required this.communitySlug,
    required this.postSlug,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  String _commentSort = 'best';
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String postId, VoidCallback? onRefetch) async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kAddComment),
        variables: {'postId': postId, 'body': body},
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(graphQLErrorMessage(result.exception, 'Could not add comment')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      _commentCtrl.clear();
      onRefetch?.call();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kPost),
        variables: {'communitySlug': widget.communitySlug, 'postSlug': widget.postSlug},
      ),
      builder: (postResult, {fetchMore, refetch}) {
        if (postResult.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: LoadingWidget()),
          );
        }
        if (postResult.hasException) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              message: graphQLErrorMessage(postResult.exception, 'Could not load post'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final post = postResult.data?['post'] as Map<String, dynamic>?;
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found')),
          );
        }

        final community = post['community'] as Map<String, dynamic>?;
        final isLocked = post['isLocked'] == true;
        final postId = post['id'].toString();

        return Scaffold(
          appBar: AppBar(
            title: Text('y/${community?['name'] ?? ''}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
              _PostActions(postId: postId),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    PostDetailHeader(post: post, dark: dark),
                    const SizedBox(height: 8),
                    PostDetailStats(post: post),
                    const Divider(),
                    _CommentSortBar(
                      sort: _commentSort,
                      onChanged: (v) => setState(() => _commentSort = v),
                    ),
                    PostCommentsList(
                      key: ValueKey('comments_$postId$_commentSort'),
                      postId: postId,
                      sort: _commentSort,
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                _CommentInput(
                  ctrl: _commentCtrl,
                  sending: _sending,
                  onSubmit: () => _submitComment(postId, () => refetch?.call()),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentSortBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onChanged;
  const _CommentSortBar({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text('Sort by: ',
              style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12)),
          DropdownButton<String>(
            value: sort,
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(fontSize: 12, color: DesignTokens.primary),
            items: ['best', 'new', 'top', 'controversial', 'old', 'qa']
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSubmit;
  const _CommentInput({required this.ctrl, required this.sending, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(top: BorderSide(color: dark ? DesignTokens.darkBorder : DesignTokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send_rounded, color: DesignTokens.primary),
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostActions extends ConsumerWidget {
  final String postId;
  const _PostActions({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        final client = ref.read(graphqlClientProvider);
        if (v == 'save') {
          await client.mutate(MutationOptions(
            document: gql(kSavePost), variables: {'postId': postId},
          ));
        } else if (v == 'report') {
          final reason = await showDialog<String>(
            context: context,
            builder: (ctx) {
              final ctrl = TextEditingController();
              return AlertDialog(
                title: const Text('Report Post'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Reason...'), autofocus: true),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Report')),
                ],
              );
            },
          );
          if (reason != null && reason.trim().isNotEmpty) {
            await client.mutate(MutationOptions(
              document: gql(kReportPost), variables: {'postId': postId, 'reason': reason},
            ));
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'save', child: Text('Save')),
        const PopupMenuItem(value: 'report', child: Text('Report')),
      ],
    );
  }
}
