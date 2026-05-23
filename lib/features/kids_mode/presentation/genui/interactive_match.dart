import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final interactiveMatchSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['InteractiveMatch']),
    'question':
        S.string(description: 'The question asking the child what to find'),
    'options': S.list(
      description: 'The emoji options to pick from',
      items: S.object(
        properties: {
          'emoji': S.string(description: 'The emoji symbol'),
          'label': S.string(description: 'The hidden text label (e.g. "Dog")'),
        },
        required: ['emoji', 'label'],
      ),
    ),
    'correctIndex': S.integer(
        description: 'The array index of the correct option (0, 1, or 2)'),
    'completeAction': A2uiSchemas.action(
      description:
          'The action triggered when the child selects the correct answer.',
    ),
  },
  required: [
    'component',
    'question',
    'options',
    'correctIndex',
    'completeAction'
  ],
);

class _MatchOption {
  final String emoji;
  final String label;

  _MatchOption({required this.emoji, required this.label});

  factory _MatchOption.fromJson(Map<String, Object?> json) {
    return _MatchOption(
      emoji: json['emoji'] as String,
      label: json['label'] as String,
    );
  }
}

class _InteractiveMatchData {
  final String question;
  final List<_MatchOption> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  _InteractiveMatchData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory _InteractiveMatchData.fromJson(Map<String, Object?> json) {
    try {
      final action = json['completeAction'] as JsonMap;
      final event = action['event'] as JsonMap;

      return _InteractiveMatchData(
        question: json['question'] as String,
        options: (json['options'] as List<Object?>)
            .map((e) => _MatchOption.fromJson(e as Map<String, Object?>))
            .toList(),
        correctIndex: json['correctIndex'] as int,
        actionName: event['name'] as String,
        actionContext: event['context'] as JsonMap,
      );
    } catch (e) {
      throw Exception('Invalid JSON for _InteractiveMatchData: $e');
    }
  }
}

class _InteractiveMatchWidget extends StatefulWidget {
  final _InteractiveMatchData data;
  final VoidCallback onCorrect;

  const _InteractiveMatchWidget({required this.data, required this.onCorrect});

  @override
  State<_InteractiveMatchWidget> createState() =>
      _InteractiveMatchWidgetState();
}

class _InteractiveMatchWidgetState extends State<_InteractiveMatchWidget> {
  int? _selectedIndex;
  bool _isSuccess = false;

  void _handleTap(int index) {
    if (_isSuccess) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == widget.data.correctIndex) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 500), widget.onCorrect);
    } else {
      HapticFeedback.vibrate();
      // Reset after a tiny delay for bad answers
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_isSuccess) {
          setState(() {
            _selectedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KidsVisualTheme.trailGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KidsVisualTheme.trailGreen, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.data.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: KidsVisualTheme.ink,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.data.options.length, (index) {
              final isSelected = _selectedIndex == index;
              final isCorrect = isSelected && index == widget.data.correctIndex;
              final isWrong = isSelected && index != widget.data.correctIndex;

              return GestureDetector(
                onTap: () => _handleTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? KidsVisualTheme.trailGreen
                        : (isWrong ? Colors.redAccent : Colors.white),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: isSelected ? 0 : 8,
                        offset: Offset(0, isSelected ? 0 : 4),
                      )
                    ],
                    border: Border.all(
                      color: isCorrect ? Colors.white : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  child: Text(
                    widget.data.options[index].emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ).animate(target: isWrong ? 1 : 0).shake(
                    hz: 4, curve: Curves.easeInOutCubic, duration: 300.ms),
              );
            }),
          ),
          if (_isSuccess) ...[
            const SizedBox(height: 20),
            const Text(
              'Great Job! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: KidsVisualTheme.trailGreen,
              ),
            ).animate().scale(curve: Curves.elasticOut),
          ]
        ],
      ),
    );
  }
}

final interactiveMatchItem = CatalogItem(
  name: 'InteractiveMatch',
  dataSchema: interactiveMatchSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _InteractiveMatchData.fromJson(json);

    return _InteractiveMatchWidget(
      data: data,
      onCorrect: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );

        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['answeredCorrectly'] = true;

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
