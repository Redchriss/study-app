import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final tapAndLearnSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['TapAndLearn']),
    'emoji': S.string(description: 'Emoji representing the object to learn'),
    'word': S.string(description: 'The word to teach'),
    'word_in_chichewa':
        S.string(description: 'Chichewa translation of the word'),
    'learnAction': A2uiSchemas.action(
      description: 'Fired after child taps and hears the word',
    ),
  },
  required: ['component', 'emoji', 'word', 'learnAction'],
);

class _TapAndLearnData {
  final String emoji;
  final String word;
  final String? wordInChichewa;
  final String actionName;
  final JsonMap actionContext;

  _TapAndLearnData({
    required this.emoji,
    required this.word,
    this.wordInChichewa,
    required this.actionName,
    required this.actionContext,
  });

  factory _TapAndLearnData.fromJson(Map<String, Object?> json) {
    final action = json['learnAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _TapAndLearnData(
      emoji: (json['emoji'] as String?) ?? '📖',
      word: (json['word'] as String?) ?? '',
      wordInChichewa: json['word_in_chichewa'] as String?,
      actionName: (event?['name'] as String?) ?? 'learned',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _TapAndLearnWidget extends StatefulWidget {
  final _TapAndLearnData data;
  final VoidCallback onLearn;

  const _TapAndLearnWidget({required this.data, required this.onLearn});

  @override
  State<_TapAndLearnWidget> createState() => _TapAndLearnWidgetState();
}

class _TapAndLearnWidgetState extends State<_TapAndLearnWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entranceAnim;
  late final Animation<Offset> _slideAnim;
  double _bounceScale = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.elasticOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.heavyImpact();
    setState(() => _bounceScale = 1.3);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _bounceScale = 1.0);
        widget.onLearn();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _entranceAnim,
        child: GestureDetector(
          onTap: _handleTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsVisualTheme.sunGold, width: 3),
              boxShadow: KidsVisualTheme.chunkyShadow(KidsVisualTheme.sunGold),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _bounceScale,
                  duration: const Duration(milliseconds: 150),
                  child: Text(widget.data.emoji,
                      style: const TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.data.word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: KidsVisualTheme.ink,
                  ),
                ),
                if (widget.data.wordInChichewa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.data.wordInChichewa!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: KidsVisualTheme.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: KidsVisualTheme.sunGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app,
                          size: 18, color: KidsVisualTheme.ink),
                      SizedBox(width: 6),
                      Text(
                        'Tap to learn!',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: KidsVisualTheme.ink,
                        ),
                      ),
                    ],
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

final tapAndLearnItem = CatalogItem(
  name: 'TapAndLearn',
  dataSchema: tapAndLearnSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _TapAndLearnData.fromJson(json);
    return _TapAndLearnWidget(
      data: data,
      onLearn: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['word'] = data.word;
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
