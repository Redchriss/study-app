import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'retention_service.dart';

class StudyMaterialProgress {
  const StudyMaterialProgress({
    required this.slug,
    required this.title,
    required this.subjectName,
    required this.contentType,
    required this.currentUnit,
    required this.totalUnits,
    required this.updatedAtEpochMs,
  });

  final String slug;
  final String title;
  final String subjectName;
  final String contentType;
  final int currentUnit;
  final int totalUnits;
  final int updatedAtEpochMs;

  double get completionRatio {
    if (totalUnits <= 0) return 0;
    if (totalUnits == 1) return 0.35;
    return (currentUnit + 1).clamp(0, totalUnits) / totalUnits;
  }

  String get progressLabel {
    if (totalUnits <= 1) {
      return contentType == 'video' ? 'Continue watching' : 'Continue studying';
    }
    return 'Page ${currentUnit + 1} of $totalUnits';
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'title': title,
        'subjectName': subjectName,
        'contentType': contentType,
        'currentUnit': currentUnit,
        'totalUnits': totalUnits,
        'updatedAtEpochMs': updatedAtEpochMs,
      };

  static StudyMaterialProgress? fromGraphQL(Map<String, dynamic>? progress) {
    final material = progress?['material'] as Map<String, dynamic>?;
    if (progress == null || material == null) return null;
    final slug = material['slug']?.toString() ?? '';
    final title = material['title']?.toString() ?? '';
    if (slug.isEmpty || title.isEmpty) return null;
    return StudyMaterialProgress(
      slug: slug,
      title: title,
      subjectName: material['subject']?['name']?.toString() ?? '',
      contentType: material['contentType']?.toString() ?? '',
      currentUnit: (progress['currentUnit'] as num?)?.toInt() ?? 0,
      totalUnits: (progress['totalUnits'] as num?)?.toInt() ?? 0,
      updatedAtEpochMs: DateTime.tryParse(progress['lastOpenedAt']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0,
    );
  }

  static StudyMaterialProgress? fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    if (slug.isEmpty || title.isEmpty) return null;
    return StudyMaterialProgress(
      slug: slug,
      title: title,
      subjectName: json['subjectName']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      currentUnit: (json['currentUnit'] as num?)?.toInt() ?? 0,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 0,
      updatedAtEpochMs: (json['updatedAtEpochMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudyProgressStore {
  static const _recentMaterialKey = 'study_recent_material';

  Future<StudyMaterialProgress?> loadLastMaterial() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentMaterialKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return StudyMaterialProgress.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMaterial({
    required String slug,
    required String title,
    required String subjectName,
    required String contentType,
    required int currentUnit,
    required int totalUnits,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = StudyMaterialProgress(
      slug: slug,
      title: title,
      subjectName: subjectName,
      contentType: contentType,
      currentUnit: currentUnit < 0 ? 0 : currentUnit,
      totalUnits: totalUnits < 0 ? 0 : totalUnits,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(_recentMaterialKey, jsonEncode(progress.toJson()));
    await RetentionService().refreshStudyReminder();
  }
}
