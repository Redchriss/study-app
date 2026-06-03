import '../../../../core/services/study_progress_store.dart';

class DashboardData {
  final String name;
  final String educationLevel;
  final int streak;
  final int points;
  final int credits;
  final bool onboardingComplete;

  final bool hasProgressData;
  final int masteryPercent;
  final int avgQuizScore;
  final int questionsPracticed;
  final int attemptCount;
  final List<String> strongestTopics;
  final List<String> weakestTopics;

  final List<String> strugglingTopics;
  final List<String> masteredTopics;

  final StudyMaterialProgress? latestProgress;

  final List<Map<String, dynamic>> recentMaterials;
  final List<Map<String, dynamic>> recentQuizAttempts;

  DashboardData({
    required this.name,
    required this.educationLevel,
    required this.streak,
    required this.points,
    required this.credits,
    required this.onboardingComplete,
    required this.hasProgressData,
    required this.masteryPercent,
    required this.avgQuizScore,
    required this.questionsPracticed,
    required this.attemptCount,
    required this.strongestTopics,
    required this.weakestTopics,
    required this.strugglingTopics,
    required this.masteredTopics,
    this.latestProgress,
    required this.recentMaterials,
    required this.recentQuizAttempts,
  });

  static const int dailyQuestionGoal = 10;

  int get dailyProgress => questionsPracticed;

  double get dailyGoalPercent =>
      (dailyProgress / dailyQuestionGoal).clamp(0.0, 1.0);

  bool get isFirstTime =>
      streak == 0 &&
      latestProgress == null &&
      !hasProgressData &&
      recentMaterials.isEmpty;

  int get nextMilestone {
    if (streak < 7) return 7;
    if (streak < 30) return 30;
    if (streak < 100) return 100;
    if (streak < 365) return 365;
    return streak + 365;
  }

  int get daysToNextMilestone => nextMilestone - streak;

  String get focusTopic =>
      (weakestTopics.isNotEmpty ? weakestTopics : strugglingTopics)
          .firstOrNull ??
      '';

  String get confidenceTopic =>
      (masteredTopics.isNotEmpty ? masteredTopics : strongestTopics)
          .firstOrNull ??
      '';

  factory DashboardData.fromGraphQL(Map<String, dynamic>? data) {
    final me = data?['me'] as Map<String, dynamic>?;
    final profile = me?['profile'] as Map<String, dynamic>?;
    final snap = data?['progressSnapshot'] as Map<String, dynamic>?;
    final learningProfile =
        data?['learningProfile'] as Map<String, dynamic>?;

    final latestProgress = StudyMaterialProgress.fromGraphQL(
      data?['latestMaterialProgress'] is Map
          ? Map<String, dynamic>.from(
              data!['latestMaterialProgress'] as Map)
          : null,
    );

    final rawRecentMaterials = (data?['recentMaterials'] as List?) ?? [];
    final recentMaterials = rawRecentMaterials
        .map((e) => e is Map<String, dynamic>
            ? e
            : <String, dynamic>{})
        .toList();

    final rawQuizAttempts = (data?['recentQuizAttempts'] as List?) ?? [];
    final recentQuizAttempts = rawQuizAttempts
        .map((e) =>
            e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();

    return DashboardData(
      name: (me?['firstName']?.toString().isNotEmpty == true)
          ? me!['firstName'].toString()
          : me?['username']?.toString() ?? 'Student',
      educationLevel:
          profile?['educationLevel']?.toString() ?? 'secondary',
      streak: (profile?['studyStreak'] as num?)?.toInt() ?? 0,
      points: (profile?['studyPoints'] as num?)?.toInt() ?? 0,
      credits: (profile?['aiCredits'] as num?)?.toInt() ?? 0,
      onboardingComplete:
          profile?['onboardingComplete'] == true,
      hasProgressData: snap?['hasData'] == true,
      masteryPercent:
          (snap?['masteryPercent'] as num?)?.toInt() ?? 0,
      avgQuizScore:
          (snap?['avgQuizScore'] as num?)?.toInt() ?? 0,
      questionsPracticed:
          (snap?['questionsPracticed'] as num?)?.toInt() ?? 0,
      attemptCount:
          (snap?['attemptCount'] as num?)?.toInt() ?? 0,
      strongestTopics:
          _toStringList(snap?['strongestTopics']),
      weakestTopics: _toStringList(snap?['weakestTopics']),
      strugglingTopics: _toStringList(
          learningProfile?['topicsStruggling']),
      masteredTopics: _toStringList(
          learningProfile?['topicsMastered']),
      latestProgress: latestProgress,
      recentMaterials: recentMaterials,
      recentQuizAttempts: recentQuizAttempts,
    );
  }

  static List<String> _toStringList(dynamic raw) =>
      ((raw as List?) ?? const [])
          .map((e) =>
              e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((s) => s.trim().isNotEmpty)
          .cast<String>()
          .toList();
}
