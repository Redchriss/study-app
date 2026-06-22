import 'dart:convert';

/// One teaching chunk of a generated study-pack lesson.
class StudyPackLessonChunk {
  const StudyPackLessonChunk({required this.heading, required this.body});

  final String heading;
  final String body;

  factory StudyPackLessonChunk.fromMap(Map<String, dynamic> map) {
    return StudyPackLessonChunk(
      heading: map['heading']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
    );
  }
}

/// A single front/back flashcard inside a study pack.
class StudyPackFlashcard {
  const StudyPackFlashcard({required this.front, required this.back});

  final String front;
  final String back;

  factory StudyPackFlashcard.fromMap(Map<String, dynamic> map) {
    return StudyPackFlashcard(
      front: (map['front'] ?? map['question'] ?? '').toString(),
      back: (map['back'] ?? map['answer'] ?? '').toString(),
    );
  }
}

/// The assembled study pack: a lesson, a generated quiz reference, and a deck.
class StudyPackData {
  const StudyPackData({
    required this.lesson,
    required this.quizSlug,
    required this.quizTitle,
    required this.quizQuestionCount,
    required this.flashcards,
  });

  final List<StudyPackLessonChunk> lesson;
  final String quizSlug;
  final String quizTitle;
  final int quizQuestionCount;
  final List<StudyPackFlashcard> flashcards;

  bool get hasQuiz => quizSlug.isNotEmpty;
  bool get hasFlashcards => flashcards.isNotEmpty;
  bool get isEmpty => lesson.isEmpty && !hasQuiz && !hasFlashcards;

  /// Tolerant parser: accepts the raw `studyPack` value, which arrives as a
  /// JSON-encoded string (graphene `JSONString`) or an already-decoded map.
  static StudyPackData? parse(dynamic raw) {
    if (raw == null) return null;
    dynamic decoded = raw;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        decoded = jsonDecode(trimmed);
      } catch (_) {
        return null;
      }
    }
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    final lesson = ((map['lesson'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) =>
            StudyPackLessonChunk.fromMap(Map<String, dynamic>.from(item)))
        .where((chunk) => chunk.body.isNotEmpty)
        .toList();

    final quiz = map['quiz'] is Map
        ? Map<String, dynamic>.from(map['quiz'] as Map)
        : const <String, dynamic>{};

    final flashcards = ((map['flashcards'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) =>
            StudyPackFlashcard.fromMap(Map<String, dynamic>.from(item)))
        .where((card) => card.front.isNotEmpty && card.back.isNotEmpty)
        .toList();

    final data = StudyPackData(
      lesson: lesson,
      quizSlug: quiz['slug']?.toString() ?? '',
      quizTitle: quiz['title']?.toString() ?? '',
      quizQuestionCount: (quiz['question_count'] as num?)?.toInt() ?? 0,
      flashcards: flashcards,
    );
    return data.isEmpty ? null : data;
  }
}
