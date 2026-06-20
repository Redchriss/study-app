import 'dart:convert';

import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

/// Renders the optional AI "story-adventure" framing of a lesson.
///
/// The backend exposes `story` as a JSON object (`{intro, choices:[{label,
/// outcome}]}`). Depending on the transport it may arrive as a [Map] or as a
/// JSON-encoded [String]; [parseStory] handles both null-safely and returns
/// `null` whenever the data is missing or malformed, so the lesson still works
/// without a story.
class KidsStoryAdventure {
  final String intro;
  final List<KidsStoryChoice> choices;

  const KidsStoryAdventure({required this.intro, required this.choices});

  static KidsStoryAdventure? parseStory(Object? raw) {
    if (raw == null) return null;
    Object? data = raw;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        data = jsonDecode(trimmed);
      } catch (_) {
        return null;
      }
    }
    if (data is! Map) return null;
    final intro = (data['intro'] as Object?)?.toString().trim() ?? '';
    if (intro.isEmpty) return null;
    final rawChoices = data['choices'];
    final choices = <KidsStoryChoice>[];
    if (rawChoices is List) {
      for (final c in rawChoices) {
        if (c is! Map) continue;
        final label = (c['label'] as Object?)?.toString().trim() ?? '';
        if (label.isEmpty) continue;
        final outcome = (c['outcome'] as Object?)?.toString().trim() ?? '';
        choices.add(KidsStoryChoice(label: label, outcome: outcome));
      }
    }
    if (choices.isEmpty) return null;
    return KidsStoryAdventure(intro: intro, choices: choices);
  }
}

class KidsStoryChoice {
  final String label;
  final String outcome;

  const KidsStoryChoice({required this.label, this.outcome = ''});
}

class KidsStoryAdventureCard extends StatefulWidget {
  const KidsStoryAdventureCard({super.key, required this.story});

  final KidsStoryAdventure story;

  @override
  State<KidsStoryAdventureCard> createState() => _KidsStoryAdventureCardState();
}

class _KidsStoryAdventureCardState extends State<KidsStoryAdventureCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    return Semantics(
      label: 'Story adventure: ${story.intro}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3D6), Color(0xFFFFE0EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text('📖', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('Story time',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: KidsVisualTheme.ink)),
              ],
            ),
            const SizedBox(height: 10),
            Text(story.intro,
                style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 12),
            ...List.generate(story.choices.length, (i) {
              final choice = story.choices[i];
              final picked = _picked == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  button: true,
                  label: 'Choice: ${choice.label}${picked ? ', selected' : ''}',
                  child: Material(
                    color: picked ? KidsVisualTheme.pathBlue : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _picked = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(choice.label,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: picked
                                        ? Colors.white
                                        : KidsVisualTheme.ink)),
                            if (picked && choice.outcome.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(choice.outcome,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: Colors.white)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
