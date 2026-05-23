import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final hintRevealSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['HintReveal']),
    'hint_text': S.string(
      description: 'The hint, 1-2 sentences, guides without giving the answer',
    ),
    'hint_emoji':
        S.string(description: 'Emoji that hints at the concept visually'),
    'hintRevealAction': A2uiSchemas.action(
      description: 'Fired when student taps to reveal hint',
    ),
  },
  required: ['component', 'hint_text', 'hint_emoji', 'hintRevealAction'],
);

class _HintRevealData {
  final String hintText;
  final String hintEmoji;
  final String actionName;
  final JsonMap actionContext;

  _HintRevealData({
    required this.hintText,
    required this.hintEmoji,
    required this.actionName,
    required this.actionContext,
  });

  factory _HintRevealData.fromJson(Map<String, Object?> json) {
    final action = json['hintRevealAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _HintRevealData(
      hintText: (json['hint_text'] as String?) ?? '',
      hintEmoji: (json['hint_emoji'] as String?) ?? '💡',
      actionName: (event?['name'] as String?) ?? 'hint_revealed',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _HintRevealWidget extends StatefulWidget {
  final _HintRevealData data;
  final VoidCallback onReveal;

  const _HintRevealWidget({required this.data, required this.onReveal});

  @override
  State<_HintRevealWidget> createState() => _HintRevealWidgetState();
}

class _HintRevealWidgetState extends State<_HintRevealWidget>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
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

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    widget.onReveal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _revealed ? Colors.amber.shade50 : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _revealed ? Colors.amber.shade300 : cs.outlineVariant,
          ),
        ),
        child: _revealed
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.data.hintEmoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hint',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.data.hintText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : InkWell(
                onTap: _reveal,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.amber.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Need a hint?',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

final hintRevealItem = CatalogItem(
  name: 'HintReveal',
  dataSchema: hintRevealSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _HintRevealData.fromJson(json);
    return _HintRevealWidget(
      data: data,
      onReveal: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
