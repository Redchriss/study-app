import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final debateCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DebateCard']),
    'question': S.string(description: 'The contested question or proposition'),
    'side_a_label': S.string(description: 'Label for position A, max 4 words'),
    'side_a_argument': S.string(
      description: 'Core argument for position A, 2-3 sentences',
    ),
    'side_b_label': S.string(description: 'Label for position B, max 4 words'),
    'side_b_argument': S.string(
      description: 'Core argument for position B, 2-3 sentences',
    ),
    'context': S.string(
      description:
          'Optional Malawian or African context that makes this debate locally relevant',
    ),
    'debateAction': A2uiSchemas.action(
      description:
          'Dispatched when student submits their side selection and reasoning',
    ),
  },
  required: [
    'component',
    'question',
    'side_a_label',
    'side_a_argument',
    'side_b_label',
    'side_b_argument',
    'debateAction',
  ],
);

class _DebateCardData {
  final String question;
  final String sideALabel;
  final String sideAArgument;
  final String sideBLabel;
  final String sideBArgument;
  final String? context;
  final String actionName;
  final JsonMap actionContext;

  _DebateCardData({
    required this.question,
    required this.sideALabel,
    required this.sideAArgument,
    required this.sideBLabel,
    required this.sideBArgument,
    this.context,
    required this.actionName,
    required this.actionContext,
  });

  factory _DebateCardData.fromJson(Map<String, Object?> json) {
    final action = json['debateAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _DebateCardData(
      question: (json['question'] as String?) ?? '',
      sideALabel: (json['side_a_label'] as String?) ?? '',
      sideAArgument: (json['side_a_argument'] as String?) ?? '',
      sideBLabel: (json['side_b_label'] as String?) ?? '',
      sideBArgument: (json['side_b_argument'] as String?) ?? '',
      context: json['context'] as String?,
      actionName: (event?['name'] as String?) ?? 'debate',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _DebateCardWidget extends StatefulWidget {
  final _DebateCardData data;
  final void Function(String selectedSide, String reasoning) onSubmit;

  const _DebateCardWidget({required this.data, required this.onSubmit});

  @override
  State<_DebateCardWidget> createState() => _DebateCardWidgetState();
}

class _DebateCardWidgetState extends State<_DebateCardWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedSide;
  final _reasoningCtrl = TextEditingController();
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
    _reasoningCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedSide == null) return;
    widget.onSubmit(_selectedSide!, _reasoningCtrl.text.trim());
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (widget.data.context != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public,
                          size: 14, color: cs.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.data.context!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildSideCard(true, theme, cs),
              const SizedBox(height: 8),
              _buildSideCard(false, theme, cs),
              if (_selectedSide != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _reasoningCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Explain why you find this side stronger...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit position'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideCard(bool isSideA, ThemeData theme, ColorScheme cs) {
    final label = isSideA ? widget.data.sideALabel : widget.data.sideBLabel;
    final argument =
        isSideA ? widget.data.sideAArgument : widget.data.sideBArgument;
    final sideId = isSideA ? 'A' : 'B';
    final selected = _selectedSide == sideId;
    final accent = isSideA ? cs.primary : cs.tertiary;

    return GestureDetector(
      onTap: _selectedSide == null
          ? () => setState(() => _selectedSide = sideId)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle, color: accent, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              argument,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

final debateCardItem = CatalogItem(
  name: 'DebateCard',
  dataSchema: debateCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _DebateCardData.fromJson(json);
    return _DebateCardWidget(
      data: data,
      onSubmit: (selectedSide, reasoning) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['selectedSide'] = selectedSide;
        finalContext['reasoning'] = reasoning;
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
