import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final simpleQuizSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['SimpleQuiz']),
    'question': S.string(
      description: 'Question in simple English or Chichewa, max 20 words',
    ),
    'options': S.list(
      description: '3 or 4 answer options',
      items: S.object(properties: {
        'emoji':
            S.string(description: 'Emoji that anchors this option visually'),
        'label': S.string(description: 'Option text, max 5 words'),
      }),
    ),
    'correct_index':
        S.integer(description: 'Zero-based index of the correct option'),
    'answerAction': A2uiSchemas.action(
      description:
          'Dispatched after answer is selected, includes isCorrect and selectedIndex',
    ),
  },
  required: [
    'component',
    'question',
    'options',
    'correct_index',
    'answerAction',
  ],
);

class _SimpleQuizOption {
  final String emoji;
  final String label;

  _SimpleQuizOption({required this.emoji, required this.label});

  factory _SimpleQuizOption.fromJson(Map<String, Object?> json) {
    return _SimpleQuizOption(
      emoji: (json['emoji'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
    );
  }
}

class _SimpleQuizData {
  final String question;
  final List<_SimpleQuizOption> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  _SimpleQuizData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory _SimpleQuizData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final optionsRaw = json['options'] as List<dynamic>?;
    return _SimpleQuizData(
      question: (json['question'] as String?) ?? '',
      options: optionsRaw
              ?.map(
                  (e) => _SimpleQuizOption.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _SimpleQuizWidget extends StatefulWidget {
  final _SimpleQuizData data;
  final void Function(bool isCorrect, int selectedIndex) onAnswer;

  const _SimpleQuizWidget({required this.data, required this.onAnswer});

  @override
  State<_SimpleQuizWidget> createState() => _SimpleQuizWidgetState();
}

class _SimpleQuizWidgetState extends State<_SimpleQuizWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  int? _showResultIndex;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 5)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex != null) return;
    setState(() {
      _selectedIndex = index;
      _showResultIndex = index;
    });
    final isCorrect = index == widget.data.correctIndex;
    if (!isCorrect) {
      _shakeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _selectedIndex = null;
            _showResultIndex = null;
          });
        }
      });
    }
    widget.onAnswer(isCorrect, index);
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
              child: Text(
                widget.data.question,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.data.options.length,
              itemBuilder: (context, i) => _buildOption(i, theme, cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index, ThemeData theme, ColorScheme cs) {
    final opt = widget.data.options[index];
    final isSelected = _selectedIndex == index;
    final isCorrect = index == widget.data.correctIndex;
    final showingResult = _showResultIndex == index;

    Color bg = cs.surface;
    if (showingResult) {
      bg = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
    }
    if (isSelected && showingResult && isCorrect) {
      bg = Colors.green.shade100;
    }

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = showingResult && !isCorrect ? _shakeAnim.value : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _select(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isCorrect ? Colors.green : Colors.red)
                  : cs.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(opt.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 6),
              Text(
                opt.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (showingResult && isCorrect) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final simpleQuizItem = CatalogItem(
  name: 'SimpleQuiz',
  dataSchema: simpleQuizSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _SimpleQuizData.fromJson(json);
    return _SimpleQuizWidget(
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
