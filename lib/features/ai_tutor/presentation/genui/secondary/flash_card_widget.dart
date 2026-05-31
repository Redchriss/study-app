import 'package:flutter/material.dart';
import 'flash_card_data.dart';
import 'flash_card_recall_button.dart';

class FlashCardWidget extends StatefulWidget {
  final FlashCardData data;
  final void Function(String rating) onRecall;

  const FlashCardWidget({super.key, required this.data, required this.onRecall});

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;
  bool _flipped = false;
  String? _rating;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entrance = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeOut));
    _flipCtrl.forward();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_rating != null) return;
    setState(() => _flipped = !_flipped);
  }

  void _rate(String rating) {
    setState(() => _rating = rating);
    widget.onRecall(rating);
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
            children: [
              GestureDetector(
                onTap: _flip,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _flipped ? cs.primaryContainer : cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.data.subjectTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.data.subjectTag!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            _flipped ? _buildBack(theme) : _buildFront(theme),
                      ),
                    ],
                  ),
                ),
              ),
              if (_flipped && _rating == null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RecallButton(
                        label: 'Missed',
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: () => _rate('missed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RecallButton(
                        label: 'Almost',
                        icon: Icons.help_outline,
                        color: Colors.amber,
                        onTap: () => _rate('almost'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RecallButton(
                        label: 'Got it',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () => _rate('got_it'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.frontText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to reveal answer',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBack(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.backText,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (widget.data.example != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.data.example!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'How well did you know this?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


