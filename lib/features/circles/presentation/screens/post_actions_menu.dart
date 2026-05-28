import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PostActions extends ConsumerWidget {
  final String postId;
  final String communitySlug;
  final bool isMod;
  final bool isPinned;
  final bool isLocked;
  final bool isRemoved;
  final Map<String, dynamic>? post;
  final VoidCallback onRefetch;

  const PostActions({
    super.key,
    required this.postId,
    required this.communitySlug,
    required this.isMod,
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

    return PopupMenuButton<String>(
      onSelected: (v) async {
        final client = ref.read(graphqlClientProvider);
        if (v == 'save') {
          await client.mutate(MutationOptions(
            document: gql(kSavePost),
            variables: {'postId': postId},
          ));
        } else if (v == 'copy_link') {
          final url = 'https://yaza.app/y/$communitySlug/post/$postId';
          await Clipboard.setData(ClipboardData(text: url));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          }
        } else if (v == 'hide') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post hidden')),
            );
          }
        } else if (v == 'crosspost') {
          if (context.mounted) {
            context.push('/y/$communitySlug/submit', extra: {'crosspostOf': post});
          }
        } else if (v == 'block_author') {
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
              document: gql(kReportPost),
              variables: {'postId': postId, 'reason': reason},
            ));
          }
        } else if (v == 'pin') {
          await client.mutate(MutationOptions(
            document: gql(kPinPost),
            variables: {'postId': postId, 'pinned': !isPinned},
          ));
          onRefetch();
        } else if (v == 'lock') {
          await client.mutate(MutationOptions(
            document: gql(kLockPost),
            variables: {'postId': postId, 'locked': !isLocked},
          ));
          onRefetch();
        } else if (v == 'remove') {
          await client.mutate(MutationOptions(
            document: gql(kRemovePost),
            variables: {'postId': postId},
          ));
          onRefetch();
        } else if (v == 'approve') {
          await client.mutate(MutationOptions(
            document: gql(kApprovePost),
            variables: {'postId': postId},
          ));
          onRefetch();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.bookmark_outline, size: 18), SizedBox(width: 8), Text('Save')])),
        const PopupMenuItem(value: 'copy_link', child: Row(children: [Icon(Icons.link, size: 18), SizedBox(width: 8), Text('Copy link')])),
        const PopupMenuItem(value: 'hide', child: Row(children: [Icon(Icons.visibility_off_outlined, size: 18), SizedBox(width: 8), Text('Hide')])),
        const PopupMenuItem(value: 'crosspost', child: Row(children: [Icon(Icons.repeat_rounded, size: 18), SizedBox(width: 8), Text('Crosspost')])),
        if (authorUsername.isNotEmpty)
          const PopupMenuItem(value: 'block_author', child: Row(children: [Icon(Icons.block, size: 18, color: DesignTokens.error), SizedBox(width: 8), Text('Block author', style: TextStyle(color: DesignTokens.error))])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 18), SizedBox(width: 8), Text('Report')])),
        if (isMod) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'pin', child: Row(children: [Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18), const SizedBox(width: 8), Text(isPinned ? 'Unpin' : 'Pin')])),
          PopupMenuItem(value: 'lock', child: Row(children: [Icon(isLocked ? Icons.lock : Icons.lock_outline, size: 18), const SizedBox(width: 8), Text(isLocked ? 'Unlock' : 'Lock')])),
          const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: DesignTokens.error), SizedBox(width: 8), Text('Remove', style: TextStyle(color: DesignTokens.error))])),
          if (isRemoved)
            const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Colors.green), SizedBox(width: 8), Text('Approve', style: TextStyle(color: Colors.green))])),
        ],
      ],
    );
  }
}
