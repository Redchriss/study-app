import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final wordBubbleSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WordBubble']),
    'bubbles': S.list(
      description: 'List of 3-5 bubbles to display',
      items: S.object(
        properties: {
          'letter_or_word': S.string(
              description: 'Single letter or short word in the bubble'),
          'sound_hint':
              S.string(description: 'How it sounds, e.g. "sounds like aah"'),
        },
        required: ['letter_or_word'],
      ),
    ),
    'popAction': A2uiSchemas.action(
      description: 'Fired each time a bubble is popped',
    ),
  },
  required: ['component', 'bubbles', 'popAction'],
);

class _BubbleSpec {
  final String letterOrWord;
  final String? soundHint;

  _BubbleSpec({required this.letterOrWord, this.soundHint});

  factory _BubbleSpec.fromJson(Map<String, Object?> json) {
    return _BubbleSpec(
      letterOrWord: (json['letter_or_word'] as String?) ?? '',
      soundHint: json['sound_hint'] as String?,
    );
  }
}

class _WordBubbleData {
  final List<_BubbleSpec> bubbles;
  final String actionName;
  final JsonMap actionContext;

  _WordBubbleData({
    required this.bubbles,
    required this.actionName,
    required this.actionContext,
  });

  factory _WordBubbleData.fromJson(Map<String, Object?> json) {
    final action = json['popAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _WordBubbleData(
      bubbles: ((json['bubbles'] as List<Object?>?) ?? [])
          .map((e) => _BubbleSpec.fromJson(e as Map<String, Object?>))
          .toList(),
      actionName: (event?['name'] as String?) ?? 'popped',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

const _bubbleColors = [
  Color(0xFF2B7FD9),
  Color(0xFF3DB86B),
  Color(0xFFFFC02D),
  Color(0xFFFF6F00),
  Color(0xFF9C27B0),
];

class _WordBubbleWidget extends StatefulWidget {
  final _WordBubbleData data;
  final void Function(String letterOrWord, int remaining) onPop;

  const _WordBubbleWidget({required this.data, required this.onPop});

  @override
  State<_WordBubbleWidget> createState() => _WordBubbleWidgetState();
}

class _WordBubbleWidgetState extends State<_WordBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Set<int> _popped = {};
  final _rand = Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pop(int index) {
    if (_popped.contains(index)) return;
    HapticFeedback.lightImpact();
    setState(() => _popped.add(index));
    final remaining = widget.data.bubbles.length - _popped.length;
    widget.onPop(widget.data.bubbles[index].letterOrWord, remaining);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _ctrl.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KidsVisualTheme.skyTop, width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Pop the bubbles!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: KidsVisualTheme.ink,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(widget.data.bubbles.length, (index) {
                if (_popped.contains(index)) {
                  return const SizedBox(width: 64, height: 64);
                }
                final color = _bubbleColors[index % _bubbleColors.length];
                final float = sin(_rand.nextDouble() * 6.28) * 4;
                return GestureDetector(
                  onTap: () => _pop(index),
                  child: Transform.translate(
                    offset: Offset(0, float),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.data.bubbles[index].letterOrWord,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_popped.length == widget.data.bubbles.length) ...[
              const SizedBox(height: 16),
              const Text(
                'All done! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: KidsVisualTheme.trailGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final wordBubbleItem = CatalogItem(
  name: 'WordBubble',
  dataSchema: wordBubbleSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _WordBubbleData.fromJson(json);
    return _WordBubbleWidget(
      data: data,
      onPop: (letterOrWord, remaining) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['letterOrWord'] = letterOrWord;
        finalContext['remainingBubbles'] = remaining;
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: finalContext,
          ),
        );
      },
    );
  },
);
