import 'package:flutter/material.dart';
import 'debate_card_data.dart';

class DebateCardWidget extends StatefulWidget {
  final DebateCardData data;
  final void Function(String selectedSide, String reasoning) onSubmit;

  const DebateCardWidget(
      {super.key, required this.data, required this.onSubmit});

  @override
  State<DebateCardWidget> createState() => _DebateCardWidgetState();
}

class _DebateCardWidgetState extends State<DebateCardWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedSide;
  final _reasoningCtrl = TextEditingController();
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _reasoningCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedSide == null) return;
    widget.onSubmit(_selectedSide!, _reasoningCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (widget.data.context != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public,
                          size: 14, color: cs.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.data.context!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildSideCard(true, theme, cs),
              const SizedBox(height: 8),
              _buildSideCard(false, theme, cs),
              if (_selectedSide != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _reasoningCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Explain why you find this side stronger...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit position'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideCard(bool isSideA, ThemeData theme, ColorScheme cs) {
    final label = isSideA ? widget.data.sideALabel : widget.data.sideBLabel;
    final argument =
        isSideA ? widget.data.sideAArgument : widget.data.sideBArgument;
    final sideId = isSideA ? 'A' : 'B';
    final selected = _selectedSide == sideId;
    final accent = isSideA ? cs.primary : cs.tertiary;

    return GestureDetector(
      onTap: _selectedSide == null
          ? () => setState(() => _selectedSide = sideId)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle, color: accent, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              argument,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
