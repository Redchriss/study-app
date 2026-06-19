import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommentActionRow extends StatelessWidget {
  final bool showReply;
  final bool collapsed;
  final VoidCallback onReply;
  final VoidCallback onSave;
  final VoidCallback onCollapse;
  final VoidCallback onReport;
  final Widget? trailing;

  const CommentActionRow({
    super.key,
    required this.showReply,
    required this.collapsed,
    required this.onReply,
    required this.onSave,
    required this.onCollapse,
    required this.onReport,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onReply,
            icon: const Icon(Icons.reply_rounded, size: 14),
            label: Text(showReply ? 'Cancel' : 'Reply',
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_outline, size: 14),
            label: const Text('Save',
                style:
                    TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onCollapse,
            icon: Icon(
                collapsed
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                size: 14),
            label: Text(collapsed ? 'Expand' : 'Collapse',
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.flag_outlined, size: 14),
            label: const Text('Report',
                style:
                    TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class CommentReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  const CommentReplyInput({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Write a reply...',
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
    );
  }
}

Future<void> saveComment(
    WidgetRef ref, String commentId, BuildContext context) async {
  final client = ref.read(graphqlClientProvider);
  await client.mutate(MutationOptions(
    document: gql(kSaveComment),
    variables: {'commentId': commentId},
  ));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment saved')),
    );
  }
}

Future<void> reportComment(
    WidgetRef ref, String commentId, BuildContext context) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: const Text('Report Comment'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason...'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Report')),
        ],
      );
    },
  );
  if (reason == null || reason.trim().isEmpty) return;
  final client = ref.read(graphqlClientProvider);
  await client.mutate(MutationOptions(
    document: gql(kReportComment),
    variables: {'commentId': commentId, 'reason': reason},
  ));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Comment reported')));
}
