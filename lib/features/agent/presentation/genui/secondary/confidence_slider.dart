import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final confidenceSliderSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ConfidenceSlider']),
    'topic': S.string(
      description: 'The topic just covered, used in context of action',
    ),
    'question': S.string(
      description:
          'Prompt shown above slider e.g. "How confident do you feel about photosynthesis?"',
    ),
    'confidenceAction': A2uiSchemas.action(
      description:
          'Dispatched when student submits rating, context includes rating (1-5) and topic',
    ),
  },
  required: ['component', 'topic', 'question', 'confidenceAction'],
);

const _labels = {
  1: 'Not sure at all',
  2: 'A bit unsure',
  3: 'Getting there',
  4: 'Pretty confident',
  5: 'I\'ve got this!',
};

const _emojis = {
  1: '😕',
  2: '😐',
  3: '🙂',
  4: '😊',
  5: '🌟',
};

class _ConfidenceSliderData {
  final String topic;
  final String question;
  final String actionName;
  final JsonMap actionContext;

  _ConfidenceSliderData({
    required this.topic,
    required this.question,
    required this.actionName,
    required this.actionContext,
  });

  factory _ConfidenceSliderData.fromJson(Map<String, Object?> json) {
    final action = json['confidenceAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _ConfidenceSliderData(
      topic: (json['topic'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'confidence_rated',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _ConfidenceSliderWidget extends StatefulWidget {
  final _ConfidenceSliderData data;
  final void Function(int rating) onSubmit;

  const _ConfidenceSliderWidget({
    required this.data,
    required this.onSubmit,
  });

  @override
  State<_ConfidenceSliderWidget> createState() =>
      _ConfidenceSliderWidgetState();
}

class _ConfidenceSliderWidgetState extends State<_ConfidenceSliderWidget>
    with SingleTickerProviderStateMixin {
  double _value = 3;
  bool _submitted = false;
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

  int get _roundedValue => _value.round();

  void _submit() {
    setState(() => _submitted = true);
    widget.onSubmit(_roundedValue);
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.data.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('😕',
                        style: TextStyle(
                            fontSize: 28, color: cs.onSurfaceVariant)),
                    Text(
                      _emojis[_roundedValue] ?? '🙂',
                      style: const TextStyle(fontSize: 48),
                    ),
                    Text('😊',
                        style: TextStyle(
                            fontSize: 28, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: cs.primary,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    thumbColor: cs.primary,
                    overlayColor: cs.primary.withValues(alpha: 0.12),
                    valueIndicatorColor: cs.primary,
                    valueIndicatorTextStyle: TextStyle(color: cs.onPrimary),
                  ),
                  child: Slider(
                    value: _value,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _roundedValue.toString(),
                    onChanged:
                        _submitted ? null : (v) => setState(() => _value = v),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[_roundedValue] ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitted ? null : _submit,
                    child: const Text('Submit'),
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

final confidenceSliderItem = CatalogItem(
  name: 'ConfidenceSlider',
  dataSchema: confidenceSliderSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ConfidenceSliderData.fromJson(json);
    return _ConfidenceSliderWidget(
      data: data,
      onSubmit: (rating) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['rating'] = rating;
        finalContext['topic'] = data.topic;
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
