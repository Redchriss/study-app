import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final storyComprehensionSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StoryComprehension']),
    'story_title': S.string(description: 'Short story title, max 5 words'),
    'story_text': S.string(
      description:
          'Story body, 3-5 sentences, simple vocabulary, Malawian names and settings',
    ),
    'question': S.string(description: 'Comprehension question about the story'),
    'options': S.list(
      description: '3 answer options, all plausible from the story',
      items: S.string(),
    ),
    'correct_index': S.integer(description: 'Index of the correct answer'),
    'answerAction':
        A2uiSchemas.action(description: 'Dispatched after answer selected'),
  },
  required: [
    'component',
    'story_title',
    'story_text',
    'question',
    'options',
    'correct_index',
    'answerAction',
  ],
);

class _StoryComprehensionData {
  final String storyTitle;
  final String storyText;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  _StoryComprehensionData({
    required this.storyTitle,
    required this.storyText,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory _StoryComprehensionData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final optionsRaw = json['options'] as List<dynamic>?;
    return _StoryComprehensionData(
      storyTitle: (json['story_title'] as String?) ?? '',
      storyText: (json['story_text'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      options: optionsRaw?.map((e) => e as String).toList() ?? [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _StoryComprehensionWidget extends StatefulWidget {
  final _StoryComprehensionData data;
  final void Function(bool isCorrect, int selectedIndex) onAnswer;

  const _StoryComprehensionWidget({required this.data, required this.onAnswer});

  @override
  State<_StoryComprehensionWidget> createState() =>
      _StoryComprehensionWidgetState();
}

class _StoryComprehensionWidgetState extends State<_StoryComprehensionWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories,
                          size: 18, color: cs.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        widget.data.storyTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.data.storyText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.data.question,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.data.options.length, (i) {
              final correct = i == widget.data.correctIndex;
              final isSelected = _selectedIndex == i;
              Color bg = cs.surface;
              if (isSelected) {
                bg = correct ? Colors.green.shade100 : Colors.red.shade100;
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
                            ? (correct ? Colors.green : Colors.red)
                            : cs.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.data.options[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected && correct)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                        if (isSelected && !correct)
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

final storyComprehensionItem = CatalogItem(
  name: 'StoryComprehension',
  dataSchema: storyComprehensionSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _StoryComprehensionData.fromJson(json);
    return _StoryComprehensionWidget(
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
