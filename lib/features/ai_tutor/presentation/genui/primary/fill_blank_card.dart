import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final fillBlankCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FillBlankCard']),
    'sentence_before': S.string(description: 'Text before the blank'),
    'sentence_after':
        S.string(description: 'Text after the blank (can be empty string)'),
    'correct_word':
        S.string(description: 'The correct word that fills the blank'),
    'distractor_words': S.list(
      description: 'Two or three plausible but wrong words',
      items: S.string(),
    ),
    'fillAction': A2uiSchemas.action(
      description:
          'Dispatched when student taps a word chip, includes selectedWord and isCorrect',
    ),
  },
  required: [
    'component',
    'sentence_before',
    'correct_word',
    'distractor_words',
    'fillAction',
  ],
);

class _FillBlankCardData {
  final String sentenceBefore;
  final String sentenceAfter;
  final String correctWord;
  final List<String> distractorWords;
  final String actionName;
  final JsonMap actionContext;

  _FillBlankCardData({
    required this.sentenceBefore,
    required this.sentenceAfter,
    required this.correctWord,
    required this.distractorWords,
    required this.actionName,
    required this.actionContext,
  });

  factory _FillBlankCardData.fromJson(Map<String, Object?> json) {
    final action = json['fillAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final distractors = json['distractor_words'] as List<dynamic>?;
    return _FillBlankCardData(
      sentenceBefore: (json['sentence_before'] as String?) ?? '',
      sentenceAfter: (json['sentence_after'] as String?) ?? '',
      correctWord: (json['correct_word'] as String?) ?? '',
      distractorWords: distractors?.map((e) => e as String).toList() ?? [],
      actionName: (event?['name'] as String?) ?? 'filled',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }

  List<String> get shuffledWords {
    final words = [correctWord, ...distractorWords]..shuffle();
    return words;
  }
}

class _FillBlankCardWidget extends StatefulWidget {
  final _FillBlankCardData data;
  final void Function(String selectedWord, bool isCorrect) onFill;

  const _FillBlankCardWidget({required this.data, required this.onFill});

  @override
  State<_FillBlankCardWidget> createState() => _FillBlankCardWidgetState();
}

class _FillBlankCardWidgetState extends State<_FillBlankCardWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedWord;
  bool? _wasCorrect;
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

  void _pick(String word) {
    if (_selectedWord != null) return;
    final correct = word == widget.data.correctWord;
    setState(() {
      _selectedWord = word;
      _wasCorrect = correct;
    });
    widget.onFill(word, correct);
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      widget.data.sentenceBefore,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _selectedWord != null
                            ? (_wasCorrect == true ? Colors.green : Colors.red)
                            : cs.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (_selectedWord != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _selectedWord!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                _wasCorrect == true ? Colors.green : Colors.red,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    Text(
                      widget.data.sentenceAfter,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.data.shuffledWords.map((word) {
                  final isSelected = _selectedWord == word;
                  return FilterChip(
                    label: Text(
                      word,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? cs.onPrimary : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _wasCorrect == true && isSelected
                        ? Colors.green
                        : (_wasCorrect == false && isSelected
                            ? Colors.red
                            : cs.primary),
                    onSelected:
                        _selectedWord == null ? (_) => _pick(word) : null,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final fillBlankCardItem = CatalogItem(
  name: 'FillBlankCard',
  dataSchema: fillBlankCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _FillBlankCardData.fromJson(json);
    return _FillBlankCardWidget(
      data: data,
      onFill: (selectedWord, isCorrect) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['selectedWord'] = selectedWord;
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
