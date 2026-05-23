import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final chichewaWordCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ChichewaWordCard']),
    'chichewa_word': S.string(description: 'The Chichewa word or phrase'),
    'english_translation': S.string(description: 'English equivalent'),
    'example_sentence_chichewa': S.string(
      description: 'Short example sentence in Chichewa, max 8 words',
    ),
    'example_sentence_english': S.string(
      description: 'English translation of the example sentence',
    ),
    'emoji': S.string(description: 'Emoji that visually represents the word'),
    'flipAction': A2uiSchemas.action(
      description: 'Fired each time card is flipped',
    ),
  },
  required: [
    'component',
    'chichewa_word',
    'english_translation',
    'emoji',
    'flipAction',
  ],
);

class _ChichewaWordCardData {
  final String chichewaWord;
  final String englishTranslation;
  final String? exampleSentenceChichewa;
  final String? exampleSentenceEnglish;
  final String emoji;
  final String actionName;
  final JsonMap actionContext;

  _ChichewaWordCardData({
    required this.chichewaWord,
    required this.englishTranslation,
    this.exampleSentenceChichewa,
    this.exampleSentenceEnglish,
    required this.emoji,
    required this.actionName,
    required this.actionContext,
  });

  factory _ChichewaWordCardData.fromJson(Map<String, Object?> json) {
    final action = json['flipAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _ChichewaWordCardData(
      chichewaWord: (json['chichewa_word'] as String?) ?? '',
      englishTranslation: (json['english_translation'] as String?) ?? '',
      exampleSentenceChichewa: json['example_sentence_chichewa'] as String?,
      exampleSentenceEnglish: json['example_sentence_english'] as String?,
      emoji: (json['emoji'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'flipped',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _ChichewaWordCardWidget extends StatefulWidget {
  final _ChichewaWordCardData data;
  final VoidCallback onFlip;

  const _ChichewaWordCardWidget({required this.data, required this.onFlip});

  @override
  State<_ChichewaWordCardWidget> createState() =>
      _ChichewaWordCardWidgetState();
}

class _ChichewaWordCardWidgetState extends State<_ChichewaWordCardWidget>
    with SingleTickerProviderStateMixin {
  bool _flipped = false;
  late final AnimationController _flipCtrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
    setState(() {
      _flipped = !_flipped;
    });
    widget.onFlip();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: GestureDetector(
          onTap: _flip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _flipped ? cs.secondaryContainer : cs.primaryContainer,
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
              children: [
                Text(widget.data.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  _flipped
                      ? widget.data.englishTranslation
                      : widget.data.chichewaWord,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _flipped
                        ? cs.onSecondaryContainer
                        : cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _flipped ? 'English' : 'Chichewa',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (_flipped && widget.data.exampleSentenceEnglish != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.data.exampleSentenceEnglish!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (!_flipped &&
                    widget.data.exampleSentenceChichewa != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.data.exampleSentenceChichewa!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  _flipped ? 'Tap for Chichewa' : 'Tap for English',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final chichewaWordCardItem = CatalogItem(
  name: 'ChichewaWordCard',
  dataSchema: chichewaWordCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ChichewaWordCardData.fromJson(json);
    return _ChichewaWordCardWidget(
      data: data,
      onFlip: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['word'] = data.chichewaWord;
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
