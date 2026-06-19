import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'post_actions_menu_items.dart';
import 'post_flair_picker.dart';

class PostActions extends ConsumerWidget {
  final String postId;
  final String communitySlug;
  final bool isMod;
  final bool isPostAuthor;
  final bool isPinned, isLocked, isRemoved;
  final Map<String, dynamic>? post;
  final VoidCallback onRefetch;

  const PostActions({
    super.key,
    required this.postId,
    required this.communitySlug,
    required this.isMod,
    this.isPostAuthor = false,
    this.isPinned = false,
    this.isLocked = false,
    this.isRemoved = false,
    this.post,
    required this.onRefetch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = post?['author'] as Map<String, dynamic>?;
    final authorUsername = author?['username']?.toString() ?? '';
    final isOc = post?['isOc'] == true;
    final isSpoiler = post?['isSpoiler'] == true;
    final canTagPost = isPostAuthor || isMod;

    return PopupMenuButton<String>(
      onSelected: (v) async {
        final client = ref.read(graphqlClientProvider);
        switch (v) {
          case 'save':
            await client.mutate(MutationOptions(
              document: gql(kSavePost),
              variables: {'postId': postId},
            ));
          case 'copy_link':
            final url = 'https://yaza.app/y/$communitySlug/post/$postId';
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            }
          case 'hide':
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post hidden')),
              );
            }
          case 'crosspost':
            if (context.mounted) {
              context.push('/y/$communitySlug/submit',
                  extra: {'crosspostOf': post});
            }
          case 'block_author':
            if (authorUsername.isEmpty) return;
            await client.mutate(MutationOptions(
              document: gql(kBlockUser),
              variables: {'username': authorUsername},
            ));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Blocked u/$authorUsername')),
              );
            }
          case 'report':
            await _reportPost(context, ref, postId);
          case 'mark_oc':
            await client.mutate(MutationOptions(
              document: gql(kMarkOc),
              variables: {'postId': postId},
            ));
            onRefetch();
          case 'mark_spoiler':
            await client.mutate(MutationOptions(
              document: gql(kMarkSpoiler),
              variables: {'postId': postId, 'isSpoiler': !isSpoiler},
            ));
            onRefetch();
          case 'set_flair':
            await _setFlair(context);
          case 'pin':
            await client.mutate(MutationOptions(
              document: gql(kPinPost),
              variables: {'postId': postId, 'pinned': !isPinned},
            ));
            onRefetch();
          case 'lock':
            await client.mutate(MutationOptions(
              document: gql(kLockPost),
              variables: {'postId': postId, 'locked': !isLocked},
            ));
            onRefetch();
          case 'remove':
            await client.mutate(MutationOptions(
              document: gql(kRemovePost),
              variables: {'postId': postId},
            ));
            onRefetch();
          case 'approve':
            await client.mutate(MutationOptions(
              document: gql(kApprovePost),
              variables: {'postId': postId},
            ));
            onRefetch();
          case 'distinguish':
            await client.mutate(MutationOptions(
              document: gql(kDistinguishPost),
              variables: {'postId': postId},
            ));
            onRefetch();
        }
      },
      itemBuilder: (_) => buildPostActionItems(
        isMod: isMod,
        canTagPost: canTagPost,
        isOc: isOc,
        isSpoiler: isSpoiler,
        isPinned: isPinned,
        isLocked: isLocked,
        isRemoved: isRemoved,
        authorUsername: authorUsername,
      ),
    );
  }

  Future<void> _setFlair(BuildContext context) async {
    final changed = await showPostFlairPicker(
      context,
      communitySlug: communitySlug,
      postId: postId,
    );
    if (changed) onRefetch();
  }

  Future<void> _reportPost(
      BuildContext context, WidgetRef ref, String postId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Report Post'),
          content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Reason...'),
              autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Report')),
          ],
        );
      },
    );
    if (reason != null && reason.trim().isNotEmpty) {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kReportPost),
        variables: {'postId': postId, 'reason': reason},
      ));
    }
  }
}
