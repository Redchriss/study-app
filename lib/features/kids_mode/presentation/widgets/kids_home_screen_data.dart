import 'package:flutter/material.dart';

class KidsHomeScreenData {
  Map<String, dynamic>? selectedSubject;
  Map<String, dynamic>? selectedTopic;
  Map<String, dynamic>? currentLesson;
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> topics = [];
  List<dynamic> quiz = [];
  bool inQuiz = false;
  bool isSpeaking = false;
  bool loading = false;
  int stars = 0;
  int streak = 0;
  bool fetchedSubjects = false;
  bool showCorrectBurst = false;
  Map<String, dynamic>? dailySummary;
  Map<String, dynamic>? subjectProgress;
  Map<String, dynamic>? lessonState;
  Map<String, dynamic>? roadmapSummary;
  Map<String, dynamic>? rewardProfile;
  List<Map<String, dynamic>> topicRoadmap = [];
  List<Map<String, dynamic>> reviewQueue = [];
  String? quizReviewHint;
  int selectedStoryChunk = 0;
  bool subjectFetchStarted = false;
  late final AnimationController burstCtrl;
}
