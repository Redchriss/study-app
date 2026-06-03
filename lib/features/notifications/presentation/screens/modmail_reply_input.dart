import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ModmailReplyInput extends StatelessWidget {
  final bool isInternal;
  final bool isSending;
  final VoidCallback onToggleInternal;
  final TextEditingController controller;
  final VoidCallback onSend;

  const ModmailReplyInput({
    super.key,
    required this.isInternal,
    required this.isSending,
    required this.onToggleInternal,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurfaceVariant : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? DesignTokens.darkBorder : DesignTokens.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggleInternal,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isInternal
                        ? DesignTokens.warning.withValues(alpha: 0.15)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: isInternal
                        ? DesignTokens.warning
                        : DesignTokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText:
                        isInternal ? 'Internal note (mods only)' : 'Reply...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: dark
                        ? DesignTokens.darkSurface
                        : DesignTokens.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                color: DesignTokens.primary,
                onPressed: isSending ? null : onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
