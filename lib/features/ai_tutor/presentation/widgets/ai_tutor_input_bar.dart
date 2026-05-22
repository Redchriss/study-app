import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class AiTutorInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final String placeholder;
  final List<String> suggestions;
  final void Function([String?]) onSend;

  const AiTutorInputBar({
    super.key,
    required this.ctrl,
    required this.sending,
    required this.placeholder,
    required this.suggestions,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suggestions.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(suggestions[i],
                      style: const TextStyle(fontSize: 11)),
                  onPressed: sending ? null : () => onSend(suggestions[i]),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          if (suggestions.isNotEmpty) const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
              border: Border(
                top: BorderSide(
                    color: dark ? DesignTokens.darkBorder : DesignTokens.border,
                    width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedPress(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Voice input coming soon'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: dark
                          ? DesignTokens.darkSurfaceVariant
                          : DesignTokens.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      size: 20,
                      color: dark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: ctrl,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: dark
                            ? DesignTokens.darkSurfaceVariant
                            : DesignTokens.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sending ? null : onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPress(
                  onTap: sending ? null : () => onSend(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: sending
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
                      color: sending
                          ? DesignTokens.textTertiary.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: sending
                        ? const Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
