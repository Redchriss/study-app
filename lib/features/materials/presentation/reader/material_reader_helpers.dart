import 'dart:convert';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'material_reader_models.dart';

String? resolveYoutubeVideoId(String url) {
  final direct = YoutubePlayerController.convertUrlToId(url);
  if (direct != null && direct.isNotEmpty) return direct;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final segments =
      uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  return segments.last;
}

List<String> buildReaderParagraphs(String pageText) {
  return pageText
      .split(RegExp(r'\n{2,}'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String buildQuickQuizPrompt({
  required String materialTitle,
  required String anchorLabel,
  required String sectionText,
}) {
  return '''
Create a mini revision quiz from this study section.

Return ONLY valid JSON using this exact shape:
{
  "title": "string",
  "questions": [
    {
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "answerIndex": 0,
      "explanation": "string"
    }
  ]
}

Rules:
- Generate exactly 3 questions.
- Each question must have exactly 4 options.
- Exactly one option must be correct.
- Keep questions grounded only in the given section.
- Make the explanation short and specific.
- No markdown fences. No commentary. JSON only.

Material: $materialTitle
Anchor: $anchorLabel

Section:
---
${sectionText.trim().isEmpty ? 'Use the material context available for this section.' : sectionText.trim()}
---
''';
}

ReaderQuickQuizData? parseQuickQuizPayload(String rawText) {
  final jsonText = extractJsonPayload(rawText);
  if (jsonText == null) return null;

  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) return null;
    final quiz =
        ReaderQuickQuizData.fromMap(Map<String, dynamic>.from(decoded));
    return quiz.isValid ? quiz : null;
  } catch (_) {
    return null;
  }
}

String? extractJsonPayload(String rawText) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return null;

  final fenceMatch =
      RegExp(r'```(?:json)?\s*([\s\S]+?)```').firstMatch(trimmed);
  if (fenceMatch != null) {
    return fenceMatch.group(1)?.trim();
  }

  final objectStart = trimmed.indexOf('{');
  final objectEnd = trimmed.lastIndexOf('}');
  if (objectStart >= 0 && objectEnd > objectStart) {
    return trimmed.substring(objectStart, objectEnd + 1);
  }
  return null;
}

String describeAiReadiness(String? readiness) {
  switch ((readiness ?? '').toLowerCase()) {
    case 'text':
      return 'AI can work directly from readable text in this upload.';
    case 'youtube':
      return 'AI can use the linked video context when transcripts are available.';
    case 'multimodal':
      return 'AI can inspect the uploaded file content for study help.';
    default:
      return 'The material is uploaded. AI features may need more readable text to work at full strength.';
  }
}
