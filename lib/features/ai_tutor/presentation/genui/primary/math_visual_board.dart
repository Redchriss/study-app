import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final mathVisualBoardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MathVisualBoard']),
    'emoji': S.string(description: 'Emoji object to use for visual counting'),
    'operand_a': S.integer(description: 'First number (shown as emoji array)'),
    'operator': S.string(
      enumValues: ['+', '-'],
      description: 'Operation to perform',
    ),
    'operand_b': S.integer(description: 'Second number'),
    'answer_choices': S.list(
      description: 'Three integer choices, one being the correct answer',
      items: S.integer(),
    ),
    'answerAction': A2uiSchemas.action(
      description: 'Dispatched when student selects answer',
    ),
  },
  required: [
    'component',
    'emoji',
    'operand_a',
    'operator',
    'operand_b',
    'answer_choices',
    'answerAction',
  ],
);

class _MathVisualBoardData {
  final String emoji;
  final int operandA;
  final String operator;
  final int operandB;
  final List<int> answerChoices;
  final String actionName;
  final JsonMap actionContext;

  _MathVisualBoardData({
    required this.emoji,
    required this.operandA,
    required this.operator,
    required this.operandB,
    required this.answerChoices,
    required this.actionName,
    required this.actionContext,
  });

  int get correctAnswer =>
      operator == '+' ? operandA + operandB : operandA - operandB;

  factory _MathVisualBoardData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final choices = json['answer_choices'] as List<dynamic>?;
    return _MathVisualBoardData(
      emoji: (json['emoji'] as String?) ?? '🍎',
      operandA: (json['operand_a'] as num?)?.toInt() ?? 0,
      operator: (json['operator'] as String?) ?? '+',
      operandB: (json['operand_b'] as num?)?.toInt() ?? 0,
      answerChoices: choices?.map((e) => (e as num).toInt()).toList() ?? [],
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _MathVisualBoardWidget extends StatefulWidget {
  final _MathVisualBoardData data;
  final void Function(bool isCorrect, int selectedAnswer) onAnswer;

  const _MathVisualBoardWidget({required this.data, required this.onAnswer});

  @override
  State<_MathVisualBoardWidget> createState() => _MathVisualBoardWidgetState();
}

class _MathVisualBoardWidgetState extends State<_MathVisualBoardWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _showSubtract = false;
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

    if (widget.data.operator == '-') {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showSubtract = true);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    final chosen = widget.data.answerChoices[index];
    widget.onAnswer(chosen == widget.data.correctAnswer, chosen);
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
              _buildVisual(cs, theme),
              const SizedBox(height: 16),
              ...List.generate(widget.data.answerChoices.length, (i) {
                final correct =
                    widget.data.answerChoices[i] == widget.data.correctAnswer;
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
                      child: Text(
                        '${widget.data.answerChoices[i]}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildVisual(ColorScheme cs, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              widget.data.operandA,
              (_) =>
                  Text(widget.data.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          if (widget.data.operator == '+') ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.add, size: 28, color: cs.primary),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                widget.data.operandB,
                (_) => Text(widget.data.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('=',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ),
          ],
          if (widget.data.operator == '-') ...[
            if (_showSubtract) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.remove, size: 28, color: Colors.red),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  widget.data.operandB,
                  (_) => Opacity(
                    opacity: 0.3,
                    child: Text(widget.data.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('=',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant)),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Watch...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
              ),
          ],
          Text(
            '${widget.data.operandA} ${widget.data.operator} ${widget.data.operandB} = ?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

final mathVisualBoardItem = CatalogItem(
  name: 'MathVisualBoard',
  dataSchema: mathVisualBoardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _MathVisualBoardData.fromJson(json);
    return _MathVisualBoardWidget(
      data: data,
      onAnswer: (isCorrect, selectedAnswer) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['isCorrect'] = isCorrect;
        finalContext['selectedAnswer'] = selectedAnswer;
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
