import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final flashCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FlashCard']),
    'front_text': S.string(description: 'Term, question, or concept to recall'),
    'back_text': S.string(description: 'Definition, answer, or explanation'),
    'subject_tag':
        S.string(description: 'Subject abbreviation e.g. BIO, CHE, PHY'),
    'example':
        S.string(description: 'Optional worked example or usage sentence'),
    'recallAction': A2uiSchemas.action(
      description: 'Dispatched after student rates recall',
    ),
  },
  required: ['component', 'front_text', 'back_text', 'recallAction'],
);

class _FlashCardData {
  final String frontText;
  final String backText;
  final String? subjectTag;
  final String? example;
  final String actionName;
  final JsonMap actionContext;

  _FlashCardData({
    required this.frontText,
    required this.backText,
    this.subjectTag,
    this.example,
    required this.actionName,
    required this.actionContext,
  });

  factory _FlashCardData.fromJson(Map<String, Object?> json) {
    final action = json['recallAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _FlashCardData(
      frontText: (json['front_text'] as String?) ?? '',
      backText: (json['back_text'] as String?) ?? '',
      subjectTag: json['subject_tag'] as String?,
      example: json['example'] as String?,
      actionName: (event?['name'] as String?) ?? 'recalled',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _FlashCardWidget extends StatefulWidget {
  final _FlashCardData data;
  final void Function(String rating) onRecall;

  const _FlashCardWidget({required this.data, required this.onRecall});

  @override
  State<_FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<_FlashCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;
  bool _flipped = false;
  String? _rating;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    if (_rating != null) return;
    setState(() => _flipped = !_flipped);
  }

  void _rate(String rating) {
    setState(() => _rating = rating);
    widget.onRecall(rating);
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
              GestureDetector(
                onTap: _flip,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _flipped ? cs.primaryContainer : cs.surface,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.data.subjectTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            _flipped ? _buildBack(theme) : _buildFront(theme),
                      ),
                    ],
                  ),
                ),
              ),
              if (_flipped && _rating == null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RecallButton(
                        label: 'Missed',
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: () => _rate('missed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RecallButton(
                        label: 'Almost',
                        icon: Icons.help_outline,
                        color: Colors.amber,
                        onTap: () => _rate('almost'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RecallButton(
                        label: 'Got it',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () => _rate('got_it'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.frontText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to reveal answer',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBack(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.backText,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (widget.data.example != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.data.example!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'How well did you know this?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final flashCardItem = CatalogItem(
  name: 'FlashCard',
  dataSchema: flashCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _FlashCardData.fromJson(json);
    return _FlashCardWidget(
      data: data,
      onRecall: (rating) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['rating'] = rating;
        finalContext['frontText'] = data.frontText;
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
