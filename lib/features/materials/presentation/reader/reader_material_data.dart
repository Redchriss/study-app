import 'dart:convert';
import 'material_reader_models_base.dart';

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
