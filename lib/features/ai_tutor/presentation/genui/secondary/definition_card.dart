import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final definitionCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DefinitionCard']),
    'term': S.string(description: 'The word or concept being defined'),
    'subject_tag': S.string(description: 'Subject abbreviation'),
    'definition': S.string(description: 'Clear definition, max 2 sentences'),
    'example': S.string(
      description: 'Real-world or exam-relevant example, max 1 sentence',
    ),
    'memory_hook': S.string(
      description: 'Optional mnemonic or memory trick to help recall',
    ),
  },
  required: ['component', 'term', 'definition', 'example'],
);

class _DefinitionCardData {
  final String term;
  final String? subjectTag;
  final String definition;
  final String example;
  final String? memoryHook;

  _DefinitionCardData({
    required this.term,
    this.subjectTag,
    required this.definition,
    required this.example,
    this.memoryHook,
  });

  factory _DefinitionCardData.fromJson(Map<String, Object?> json) {
    return _DefinitionCardData(
      term: (json['term'] as String?) ?? '',
      subjectTag: json['subject_tag'] as String?,
      definition: (json['definition'] as String?) ?? '',
      example: (json['example'] as String?) ?? '',
      memoryHook: json['memory_hook'] as String?,
    );
  }
}

class _DefinitionCardWidget extends StatefulWidget {
  final _DefinitionCardData data;
  const _DefinitionCardWidget({required this.data});

  @override
  State<_DefinitionCardWidget> createState() => _DefinitionCardWidgetState();
}

class _DefinitionCardWidgetState extends State<_DefinitionCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    if (widget.data.subjectTag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.data.subjectTag!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    Text(
                      'Definition',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.data.term,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.data.definition,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('e.g. ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          )),
                      Expanded(
                        child: Text(
                          widget.data.example,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.data.memoryHook != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: cs.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.data.memoryHook!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.tertiary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
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

final definitionCardItem = CatalogItem(
  name: 'DefinitionCard',
  dataSchema: definitionCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _DefinitionCardData.fromJson(json);
    return _DefinitionCardWidget(data: data);
  },
);
