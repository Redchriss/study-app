import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final motivationCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MotivationCard']),
    'message': S.string(
      description:
          'Encouraging message, max 2 sentences. Respectful, not childish.',
    ),
    'reframe': S.string(
      description:
          'One sentence that reframes the difficult concept as approachable',
    ),
    'action_prompt': S.string(
      description:
          'What the student should try next, e.g. "Let\'s try a different example."',
    ),
  },
  required: ['component', 'message', 'reframe'],
);

class _MotivationCardData {
  final String message;
  final String reframe;
  final String? actionPrompt;

  _MotivationCardData({
    required this.message,
    required this.reframe,
    this.actionPrompt,
  });

  factory _MotivationCardData.fromJson(Map<String, Object?> json) {
    return _MotivationCardData(
      message: (json['message'] as String?) ?? '',
      reframe: (json['reframe'] as String?) ?? '',
      actionPrompt: json['action_prompt'] as String?,
    );
  }
}

class _MotivationCardWidget extends StatefulWidget {
  final _MotivationCardData data;

  const _MotivationCardWidget({required this.data});

  @override
  State<_MotivationCardWidget> createState() => _MotivationCardWidgetState();
}

class _MotivationCardWidgetState extends State<_MotivationCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 0,
          color: cs.tertiaryContainer.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.tertiary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: cs.tertiary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Keep going',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.data.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.refresh, size: 16, color: cs.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.data.reframe,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.data.actionPrompt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.data.actionPrompt!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final motivationCardItem = CatalogItem(
  name: 'MotivationCard',
  dataSchema: motivationCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _MotivationCardData.fromJson(json);
    return _MotivationCardWidget(data: data);
  },
);
