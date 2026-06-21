import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class AgentInputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final bool sending;
  final String placeholder;
  final List<String> suggestions;
  final void Function([String?]) onSend;
  const AgentInputBar({
    super.key,
    required this.ctrl,
    required this.sending,
    required this.placeholder,
    required this.suggestions,
    required this.onSend,
  });

  @override
  State<AgentInputBar> createState() => _AgentInputBarState();
}

class _AgentInputBarState extends State<AgentInputBar> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.suggestions.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(widget.suggestions[i],
                      style: const TextStyle(fontSize: 11)),
                  onPressed: widget.sending ? null : () => widget.onSend(widget.suggestions[i]),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          if (widget.suggestions.isNotEmpty) const SizedBox(height: 6),
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
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: widget.ctrl,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
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
                      onSubmitted: (_) => widget.sending ? null : widget.onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPress(
                  onTap: widget.sending ? null : () => widget.onSend(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: widget.sending
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
                      color: widget.sending
                          ? DesignTokens.textTertiary.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: widget.sending
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
