import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final pictureQuizSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['PictureQuiz']),
    'picture_emoji':
        S.string(description: 'Large emoji representing the subject'),
    'picture_label':
        S.string(description: 'Name of what is shown, displayed under emoji'),
    'question':
        S.string(description: 'Question about the picture, max 15 words'),
    'options': S.list(
      description: '3 answer options as plain strings',
      items: S.string(),
    ),
    'correct_index':
        S.integer(description: 'Zero-based index of the correct answer'),
    'answerAction':
        A2uiSchemas.action(description: 'Dispatched after answer selected'),
  },
  required: [
    'component',
    'picture_emoji',
    'question',
    'options',
    'correct_index',
    'answerAction',
  ],
);

class _PictureQuizData {
  final String pictureEmoji;
  final String pictureLabel;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  _PictureQuizData({
    required this.pictureEmoji,
    required this.pictureLabel,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory _PictureQuizData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final optionsRaw = json['options'] as List<dynamic>?;
    return _PictureQuizData(
      pictureEmoji: (json['picture_emoji'] as String?) ?? '',
      pictureLabel: (json['picture_label'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      options: optionsRaw?.map((e) => e as String).toList() ?? [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _PictureQuizWidget extends StatefulWidget {
  final _PictureQuizData data;
  final void Function(bool isCorrect, int selectedIndex) onAnswer;

  const _PictureQuizWidget({required this.data, required this.onAnswer});

  @override
  State<_PictureQuizWidget> createState() => _PictureQuizWidgetState();
}

class _PictureQuizWidgetState extends State<_PictureQuizWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
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
    _ctrl.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    widget.onAnswer(index == widget.data.correctIndex, index);
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(widget.data.pictureEmoji,
                        style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.pictureLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.data.question,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ...List.generate(widget.data.options.length, (i) {
                final isCorrect = i == widget.data.correctIndex;
                final isSelected = _selectedIndex == i;
                Color bg = cs.surface;
                if (isSelected) {
                  bg = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _select(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : cs.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.data.options[i],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected && isCorrect)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 22),
                          if (isSelected && !isCorrect)
                            const Icon(Icons.cancel,
                                color: Colors.red, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

final pictureQuizItem = CatalogItem(
  name: 'PictureQuiz',
  dataSchema: pictureQuizSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _PictureQuizData.fromJson(json);
    return _PictureQuizWidget(
      data: data,
      onAnswer: (isCorrect, selectedIndex) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['isCorrect'] = isCorrect;
        finalContext['selectedIndex'] = selectedIndex;
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
