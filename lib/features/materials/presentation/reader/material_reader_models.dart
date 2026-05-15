import 'dart:convert';

class ReaderStudySelection {
  const ReaderStudySelection({
    required this.unitIndex,
    required this.anchorLabel,
    required this.selectedText,
  });

  final int unitIndex;
  final String anchorLabel;
  final String selectedText;
}

typedef ReaderSelectionCallback = Future<void> Function(ReaderStudySelection selection);

class ReaderProgressData {
  const ReaderProgressData({
    required this.currentUnit,
    required this.totalUnits,
    required this.progressPercent,
    required this.lastPositionLabel,
  });

  final int currentUnit;
  final int totalUnits;
  final double progressPercent;
  final String lastPositionLabel;

  factory ReaderProgressData.fromMap(Map<String, dynamic> map) {
    return ReaderProgressData(
      currentUnit: (map['currentUnit'] as num?)?.toInt() ?? 0,
      totalUnits: (map['totalUnits'] as num?)?.toInt() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toDouble() ?? 0,
      lastPositionLabel: map['lastPositionLabel']?.toString() ?? '',
    );
  }
}

class ReaderAnnotationData {
  const ReaderAnnotationData({
    required this.id,
    required this.unitIndex,
    required this.anchorLabel,
    required this.selectedText,
    required this.noteText,
    required this.color,
  });

  final String id;
  final int unitIndex;
  final String anchorLabel;
  final String selectedText;
  final String noteText;
  final String color;

  bool get isHighlight => noteText.trim().isEmpty && selectedText.trim().isNotEmpty;

  String get displayAnchor => anchorLabel.trim().isNotEmpty ? anchorLabel : 'Section ${unitIndex + 1}';

  factory ReaderAnnotationData.fromMap(Map<String, dynamic> map) {
    return ReaderAnnotationData(
      id: map['id']?.toString() ?? '',
      unitIndex: (map['unitIndex'] as num?)?.toInt() ?? 0,
      anchorLabel: map['anchorLabel']?.toString() ?? '',
      selectedText: map['selectedText']?.toString() ?? '',
      noteText: map['noteText']?.toString() ?? '',
      color: map['color']?.toString() ?? 'amber',
    );
  }
}

class ReaderAiTaskData {
  const ReaderAiTaskData({
    required this.taskType,
    required this.status,
    required this.statusLabel,
    required this.isActive,
    required this.errorMessage,
  });

  final String taskType;
  final String status;
  final String statusLabel;
  final bool isActive;
  final String errorMessage;

  factory ReaderAiTaskData.fromMap(Map<String, dynamic> map) {
    return ReaderAiTaskData(
      taskType: map['taskType']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      statusLabel: map['statusLabel']?.toString() ?? '',
      isActive: map['isActive'] == true,
      errorMessage: map['errorMessage']?.toString() ?? '',
    );
  }
}

class ReaderFlashcardData {
  const ReaderFlashcardData({
    required this.front,
    required this.back,
  });

  final String front;
  final String back;

  factory ReaderFlashcardData.fromMap(Map<String, dynamic> map) {
    return ReaderFlashcardData(
      front: map['front']?.toString().trim() ?? '',
      back: map['back']?.toString().trim() ?? '',
    );
  }
}

class ReaderQuickQuizQuestion {
  const ReaderQuickQuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  factory ReaderQuickQuizQuestion.fromMap(Map<String, dynamic> map) {
    final options = ((map['options'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final rawIndex = (map['answerIndex'] as num?)?.toInt() ?? 0;
    final safeIndex = options.isEmpty ? 0 : rawIndex.clamp(0, options.length - 1).toInt();
    return ReaderQuickQuizQuestion(
      question: map['question']?.toString().trim() ?? '',
      options: options,
      answerIndex: safeIndex,
      explanation: map['explanation']?.toString().trim() ?? '',
    );
  }
}

class ReaderQuickQuizData {
  const ReaderQuickQuizData({
    required this.title,
    required this.questions,
  });

  final String title;
  final List<ReaderQuickQuizQuestion> questions;

  bool get isValid => questions.isNotEmpty && questions.every((item) => item.question.isNotEmpty && item.options.length >= 2);

  factory ReaderQuickQuizData.fromMap(Map<String, dynamic> map) {
    return ReaderQuickQuizData(
      title: map['title']?.toString().trim().isNotEmpty == true
          ? map['title'].toString().trim()
          : 'Quick Revision Quiz',
      questions: ((map['questions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ReaderQuickQuizQuestion.fromMap(Map<String, dynamic>.from(item)))
          .where((item) => item.question.isNotEmpty && item.options.length >= 2)
          .toList(),
    );
  }
}

class ReaderMaterialData {
  const ReaderMaterialData({
    required this.id,
    required this.slug,
    required this.title,
    required this.subjectName,
    required this.contentType,
    required this.contentText,
    required this.fileUrl,
    required this.youtubeEmbedUrl,
    required this.aiSummary,
    required this.aiFlashcardsJson,
    required this.progress,
    required this.annotations,
    required this.aiTasks,
  });

  final String id;
  final String slug;
  final String title;
  final String subjectName;
  final String contentType;
  final String contentText;
  final String fileUrl;
  final String youtubeEmbedUrl;
  final String aiSummary;
  final String aiFlashcardsJson;
  final ReaderProgressData? progress;
  final List<ReaderAnnotationData> annotations;
  final List<ReaderAiTaskData> aiTasks;

  bool get isPdf => contentType == 'pdf' || fileUrl.toLowerCase().endsWith('.pdf');
  bool get isReadableText => contentType == 'text' && contentText.trim().isNotEmpty;
  bool get isVideo => contentType == 'video' && youtubeEmbedUrl.trim().isNotEmpty;
  bool get isImage => contentType == 'image' && fileUrl.trim().isNotEmpty;

  List<String> get textPages {
    final cleaned = contentText
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (cleaned.isEmpty) return const <String>[];

    final paragraphs = cleaned.split('\n\n');
    final pages = <String>[];
    final buffer = StringBuffer();
    var currentLength = 0;

    for (final paragraph in paragraphs) {
      final block = paragraph.trim();
      if (block.isEmpty) continue;
      final nextLength = currentLength + block.length;
      if (nextLength > 1300 && currentLength > 0) {
        pages.add(buffer.toString().trim());
        buffer.clear();
        currentLength = 0;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
        currentLength += 2;
      }
      buffer.write(block);
      currentLength += block.length;
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }
    return pages;
  }

  List<ReaderFlashcardData> get flashcards {
    if (aiFlashcardsJson.trim().isEmpty) return const <ReaderFlashcardData>[];
    try {
      final decoded = jsonDecode(aiFlashcardsJson);
      if (decoded is! List) return const <ReaderFlashcardData>[];
      return decoded
          .whereType<Map>()
          .map((item) => ReaderFlashcardData.fromMap(Map<String, dynamic>.from(item)))
          .where((item) => item.front.isNotEmpty && item.back.isNotEmpty)
          .toList();
    } catch (_) {
      return const <ReaderFlashcardData>[];
    }
  }

  ReaderAiTaskData? taskFor(String taskType) {
    for (final task in aiTasks) {
      if (task.taskType == taskType) return task;
    }
    return null;
  }

  factory ReaderMaterialData.fromMap(String slug, Map<String, dynamic> map) {
    return ReaderMaterialData(
      id: map['id']?.toString() ?? '',
      slug: slug,
      title: map['title']?.toString() ?? 'Study mode',
      subjectName: map['subject']?['name']?.toString() ?? '',
      contentType: map['contentType']?.toString().toLowerCase() ?? '',
      contentText: map['contentText']?.toString() ?? '',
      fileUrl: map['fileUrl']?.toString() ?? '',
      youtubeEmbedUrl: map['youtubeEmbedUrl']?.toString() ?? '',
      aiSummary: map['aiSummary']?.toString() ?? '',
      aiFlashcardsJson: map['aiFlashcardsJson']?.toString() ?? '',
      progress: map['myProgress'] is Map
          ? ReaderProgressData.fromMap(Map<String, dynamic>.from(map['myProgress'] as Map))
          : null,
      annotations: ((map['myAnnotations'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ReaderAnnotationData.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      aiTasks: ((map['aiTasks'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ReaderAiTaskData.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
