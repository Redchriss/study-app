import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final emojiStoryCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['EmojiStoryCard']),
    'emoji': S.string(
        description: 'A single, very descriptive emoji character (e.g. 🐶)'),
    'text':
        S.string(description: 'Short, fun, simple sentence for a kid to read'),
  },
  required: ['component', 'emoji', 'text'],
);

class _EmojiStoryCardData {
  final String emoji;
  final String text;

  _EmojiStoryCardData({required this.emoji, required this.text});

  factory _EmojiStoryCardData.fromJson(Map<String, Object?> json) {
    try {
      return _EmojiStoryCardData(
        emoji: json['emoji'] as String,
        text: json['text'] as String,
      );
    } catch (e) {
      throw Exception('Invalid JSON for _EmojiStoryCardData: $e');
    }
  }
}

class _EmojiStoryCardWidget extends StatelessWidget {
  final _EmojiStoryCardData data;

  const _EmojiStoryCardWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: KidsVisualTheme.pathBlue, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.emoji,
            style: const TextStyle(fontSize: 64),
          )
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack)
              .rotate(begin: -0.1, end: 0, duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            data.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: KidsVisualTheme.ink,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

final emojiStoryCardItem = CatalogItem(
  name: 'EmojiStoryCard',
  dataSchema: emojiStoryCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _EmojiStoryCardData.fromJson(json);

    return _EmojiStoryCardWidget(data: data);
  },
);
