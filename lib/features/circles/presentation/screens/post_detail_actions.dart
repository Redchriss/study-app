import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommentSortBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onChanged;
  const CommentSortBar(
      {super.key, required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text('Sort by: ',
              style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12)),
          DropdownButton<String>(
            value: sort,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(fontSize: 12, color: DesignTokens.primary),
            items: ['best', 'new', 'top', 'controversial', 'old', 'qa']
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
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

class CommentInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSubmit;
  const CommentInput(
      {super.key,
      required this.ctrl,
      required this.sending,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(
            top: BorderSide(
                color: dark ? DesignTokens.darkBorder : DesignTokens.border)),
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: DesignTokens.primary),
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class PostActions extends ConsumerWidget {
  final String postId;
  final String communitySlug;
  final bool isMod;
  final bool isPinned;
  final bool isLocked;
  final bool isRemoved;
  final VoidCallback onRefetch;

  const PostActions({
    super.key,
    required this.postId,
    required this.communitySlug,
    required this.isMod,
    this.isPinned = false,
    this.isLocked = false,
    this.isRemoved = false,
    required this.onRefetch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        final client = ref.read(graphqlClientProvider);
        if (v == 'save') {
          await client.mutate(MutationOptions(
            document: gql(kSavePost),
            variables: {'postId': postId},
          ));
        } else if (v == 'report') {
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
        const PopupMenuItem(
            value: 'save',
            child: Row(
              children: [
                Icon(Icons.bookmark_outline, size: 18),
                SizedBox(width: 8),
                Text('Save')
              ],
            )),
        const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18),
                SizedBox(width: 8),
                Text('Report')
              ],
            )),
        if (isMod) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(isPinned ? 'Unpin' : 'Pin'),
                ],
              )),
          PopupMenuItem(
              value: 'lock',
              child: Row(
                children: [
                  Icon(isLocked ? Icons.lock : Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(isLocked ? 'Unlock' : 'Lock'),
                ],
              )),
          const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: DesignTokens.error),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: DesignTokens.error)),
                ],
              )),
          if (isRemoved)
            const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Approve', style: TextStyle(color: Colors.green)),
                  ],
                )),
        ],
      ],
    );
  }
}
