import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CommentSortBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onChanged;
  const CommentSortBar(
      {super.key, required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sorts = ['best', 'new', 'top', 'controversial', 'old', 'qa'];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: sorts.map((s) {
          final sel = sort == s;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(s.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
              selected: sel,
              onSelected: (_) => onChanged(s),
            ),
          );
        }).toList(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                maxLines: 3,
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
              onPressed: sending ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
