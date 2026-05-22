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
