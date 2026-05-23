import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommentSortBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onChanged;
  const CommentSortBar({super.key, required this.sort, required this.onChanged});

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

class CommentInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSubmit;
  const CommentInput({super.key, required this.ctrl, required this.sending, required this.onSubmit});

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

class PostActions extends ConsumerWidget {
  final String postId;
  const PostActions({super.key, required this.postId});

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
