import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final storyChoiceCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StoryChoiceCard']),
    'story_text': S.string(
      description: 'Story paragraph, 2-3 short sentences, simple vocabulary',
    ),
    'choice_a': S.string(description: 'First story branch option, max 6 words'),
    'choice_b':
        S.string(description: 'Second story branch option, max 6 words'),
    'choiceAction': A2uiSchemas.action(
      description: 'Dispatched when child taps a choice',
    ),
  },
  required: ['component', 'story_text', 'choice_a', 'choice_b', 'choiceAction'],
);

class _StoryChoiceCardData {
  final String storyText;
  final String choiceA;
  final String choiceB;
  final String actionName;
  final JsonMap actionContext;

  _StoryChoiceCardData({
    required this.storyText,
    required this.choiceA,
    required this.choiceB,
    required this.actionName,
    required this.actionContext,
  });

  factory _StoryChoiceCardData.fromJson(Map<String, Object?> json) {
    final action = json['choiceAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _StoryChoiceCardData(
      storyText: (json['story_text'] as String?) ?? '',
      choiceA: (json['choice_a'] as String?) ?? '',
      choiceB: (json['choice_b'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'chose',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _StoryChoiceCardWidget extends StatefulWidget {
  final _StoryChoiceCardData data;
  final void Function(int choiceIndex, String choiceLabel) onChoice;

  const _StoryChoiceCardWidget({required this.data, required this.onChoice});

  @override
  State<_StoryChoiceCardWidget> createState() => _StoryChoiceCardWidgetState();
}

class _StoryChoiceCardWidgetState extends State<_StoryChoiceCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;
  bool _chosen = false;

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

  void _pick(int choice) {
    if (_chosen) return;
    _chosen = true;
    HapticFeedback.selectionClick();
    final label = choice == 0 ? widget.data.choiceA : widget.data.choiceB;
    widget.onChoice(choice, label);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KidsVisualTheme.sunGold, width: 3),
            boxShadow: KidsVisualTheme.chunkyShadow(KidsVisualTheme.sunGold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '📖 Choose what happens next!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KidsVisualTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.storyText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: KidsVisualTheme.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceButton(
                      label: widget.data.choiceA,
                      emoji: '🌟',
                      onTap: () => _pick(0),
                      disabled: _chosen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceButton(
                      label: widget.data.choiceB,
                      emoji: '🚀',
                      onTap: () => _pick(1),
                      disabled: _chosen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;
  final bool disabled;

  const _ChoiceButton({
    required this.label,
    required this.emoji,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: disabled
              ? KidsVisualTheme.inkMuted.withValues(alpha: 0.2)
              : KidsVisualTheme.pathBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: disabled ? KidsVisualTheme.inkMuted : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final storyChoiceCardItem = CatalogItem(
  name: 'StoryChoiceCard',
  dataSchema: storyChoiceCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _StoryChoiceCardData.fromJson(json);
    return _StoryChoiceCardWidget(
      data: data,
      onChoice: (choiceIndex, choiceLabel) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['choiceIndex'] = choiceIndex;
        finalContext['choiceLabel'] = choiceLabel;
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
