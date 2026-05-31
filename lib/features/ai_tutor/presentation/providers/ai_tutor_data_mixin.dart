import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'ai_tutor_state.dart';
import '../screens/ai_tutor_data_service.dart';
import '../../../../core/graphql/queries/domain/ai_queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

mixin AiTutorDataMixin on Notifier<AiTutorState> {
  late AiTutorDataService dataService;

  Future<void> loadLearningProfile() async {
    try {
      final profile = await dataService.loadLearningProfile();
      if (profile == null) return;
      state = state.copyWith(
        learningStyle:
            (profile['learningStyle']?.toString().trim().isNotEmpty == true)
                ? profile['learningStyle'].toString()
                : 'mixed',
        prefersExamples: profile['prefersExamples'] as bool? ?? true,
        prefersStepByStep: profile['prefersStepByStep'] as bool? ?? true,
        detailLevel: profile['detailLevel'] as int? ?? 2,
      );
    } catch (_) {}
  }

  Future<void> loadTutorSnapshot() async {
    try {
      final snapshot = await dataService.loadTutorSnapshot();
      if (snapshot == null) return;
      state = state.copyWith(
        topicStates: ((snapshot['topicStates'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        memories: ((snapshot['memories'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        activePlan: snapshot['latestPlan'] is Map
            ? Map<String, dynamic>.from(snapshot['latestPlan'] as Map)
            : null,
        reviewCount: (snapshot['reviewCount'] as num?)?.toInt() ?? 0,
        snapshotLoading: false,
      );
    } catch (_) {
      state = state.copyWith(snapshotLoading: false);
    }
  }

  Future<void> loadChatHistory() async {
    try {
      final sessions = await dataService.loadChatHistory();
      state = state.copyWith(
        chatHistory: sessions
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> restoreSession(String id) async {
    try {
      final msgs = await dataService.restoreSession(id);
      final newItems = <ConversationItem>[];
      for (final m in msgs.whereType<Map>()) {
        newItems.add(TextItem(
            text: m['messageText'] as String? ?? '',
            isUser: m['isUser'] as bool? ?? false,
            id: m['id']?.toString()));
      }
      state = state.copyWith(
        sessionId: id,
        conversationItems: newItems,
      );
    } catch (_) {}
  }

  Future<void> createAdaptivePlan(String? goalText) async {
    final payload = await dataService.createAdaptivePlan(
      goal: (goalText?.trim().isEmpty ?? true) ? null : goalText?.trim(),
      subjectName: state.topicStates.isNotEmpty
          ? state.topicStates.first['subjectName']?.toString()
          : null,
      studyMode: state.studyMode,
    );
    if (payload?['success'] == true && payload?['plan'] is Map) {
      state = state.copyWith(
        activePlan: Map<String, dynamic>.from(payload!['plan'] as Map),
      );
      loadTutorSnapshot();
      return;
    }
    final errMsg = (payload?['errors'] as List?)?.cast<String>().join(', ');
    state = state.copyWith(
      error: errMsg?.isNotEmpty == true ? errMsg : 'Could not build a plan.',
    );
  }

  Future<void> saveLearningProfile({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) async {
    state = state.copyWith(profileSaving: true);
    try {
      final payload = await dataService.saveLearningProfile(
        learningStyle: learningStyle,
        prefersExamples: prefersExamples,
        prefersStepByStep: prefersStepByStep,
        detailLevel: detailLevel,
      );
      if (payload?['success'] == true) {
        state = state.copyWith(
          learningStyle: learningStyle,
          prefersExamples: prefersExamples,
          prefersStepByStep: prefersStepByStep,
          detailLevel: detailLevel,
        );
      }
    } finally {
      state = state.copyWith(profileSaving: false);
    }
  }

  Future<void> setMessageFeedback(int index, String? feedback) async {
    if (index < 0 || index >= state.conversationItems.length) return;
    final item = state.conversationItems[index];
    if (item is! TextItem) return;
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kSetMessageFeedback),
      variables: {
        'messageId': item.id,
        'feedback': feedback,
      },
    ));
  }
}
