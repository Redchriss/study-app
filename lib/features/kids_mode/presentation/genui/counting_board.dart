import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final countingBoardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['CountingBoard']),
    'emoji': S.string(description: 'Single emoji to repeat, e.g. 🥭 or 🐐'),
    'count': S.integer(description: 'How many emoji to show, between 1 and 10'),
    'choices': S.list(
      description: 'Exactly 3 number choices, one equals count',
      items: S.integer(),
    ),
    'countAction': A2uiSchemas.action(
      description: 'Dispatched when child selects an answer',
    ),
  },
  required: ['component', 'emoji', 'count', 'choices', 'countAction'],
);

class _CountingBoardData {
  final String emoji;
  final int count;
  final List<int> choices;
  final String actionName;
  final JsonMap actionContext;

  _CountingBoardData({
    required this.emoji,
    required this.count,
    required this.choices,
    required this.actionName,
    required this.actionContext,
  });

  factory _CountingBoardData.fromJson(Map<String, Object?> json) {
    final action = json['countAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _CountingBoardData(
      emoji: (json['emoji'] as String?) ?? '⭐',
      count: ((json['count'] as int?) ?? 3).clamp(1, 10),
      choices: ((json['choices'] as List<Object?>?)?.cast<int>() ?? [1, 2, 3]),
      actionName: (event?['name'] as String?) ?? 'counted',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _CountingBoardWidget extends StatefulWidget {
  final _CountingBoardData data;
  final void Function(int selected, int correct, bool isCorrect) onAnswer;

  const _CountingBoardWidget({required this.data, required this.onAnswer});

  @override
  State<_CountingBoardWidget> createState() => _CountingBoardWidgetState();
}

class _CountingBoardWidgetState extends State<_CountingBoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entranceAnim;
  late final Animation<Offset> _slideAnim;
  int? _selectedIdx;
  bool? _wasCorrect;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
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

  void _selectAnswer(int idx) {
    if (_selectedIdx != null) return;
    final selected = widget.data.choices[idx];
    final correct = selected == widget.data.count;
    setState(() {
      _selectedIdx = idx;
      _wasCorrect = correct;
    });
    if (correct) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onAnswer(selected, widget.data.count, correct);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _entranceAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KidsVisualTheme.pathBlue, width: 3),
            boxShadow: KidsVisualTheme.chunkyShadow(KidsVisualTheme.pathBlue),
          ),
          child: Column(
            children: [
              const Text(
                'How many?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: KidsVisualTheme.ink,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(widget.data.count, (_) {
                  return Text(widget.data.emoji,
                      style: const TextStyle(fontSize: 36));
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(widget.data.choices.length, (idx) {
                  final val = widget.data.choices[idx];
                  final isSelected = _selectedIdx == idx;
                  final isCorrect = isSelected && _wasCorrect == true;
                  final isWrong = isSelected && _wasCorrect == false;
                  return GestureDetector(
                    onTap: () => _selectAnswer(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect
                            ? KidsVisualTheme.trailGreen
                            : (isWrong ? Colors.redAccent : KidsVisualTheme.pathBlue),
                      ),
                      child: Center(
                        child: Text(
                          '$val',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final countingBoardItem = CatalogItem(
  name: 'CountingBoard',
  dataSchema: countingBoardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _CountingBoardData.fromJson(json);
    return _CountingBoardWidget(
      data: data,
      onAnswer: (selected, correct, isCorrect) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['selectedCount'] = selected;
        finalContext['correctCount'] = correct;
        finalContext['isCorrect'] = isCorrect;
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
