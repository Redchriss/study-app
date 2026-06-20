import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';

class AgentDataService {
  final Ref _ref;
  AgentDataService(this._ref);

  Future<Map<String, dynamic>?> loadLearningProfile() async {
    final result = await _ref.read(graphqlClientProvider).query(
          QueryOptions(
            document: gql(kLearningProfile),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
    return result.data?['learningProfile'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> loadTutorSnapshot() async {
    final result = await _ref.read(graphqlClientProvider).query(
          QueryOptions(
            document: gql(kTutorSnapshot),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
    return result.data?['tutorSnapshot'] as Map<String, dynamic>?;
  }

  Future<List<dynamic>> loadChatHistory() async {
    final result = await _ref.read(graphqlClientProvider).query(
          QueryOptions(
            document: gql(kChatSessions),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
    return (result.data?['chatSessions'] as List?) ?? [];
  }

  Future<List<dynamic>> restoreSession(String sessionId) async {
    final result = await _ref.read(graphqlClientProvider).query(
          QueryOptions(
            document: gql(kChatMessages),
            variables: {'sessionId': sessionId},
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
    return (result.data?['chatMessages'] as List?) ?? [];
  }

  Future<Map<String, dynamic>?> createAdaptivePlan({
    String? goal,
    String? subjectName,
    required String studyMode,
  }) async {
    final result = await _ref.read(graphqlClientProvider).mutate(
          MutationOptions(
            document: gql(kCreateAdaptiveStudyPlan),
            variables: {
              'goal': goal,
              'subjectName': subjectName,
              'studyMode': studyMode,
            },
          ),
        );
    return result.data?['createAdaptiveStudyPlan'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> saveLearningProfile({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) async {
    final result = await _ref.read(graphqlClientProvider).mutate(
          MutationOptions(
            document: gql(kUpdateLearningProfile),
            variables: {
              'learningStyle': learningStyle,
              'prefersExamples': prefersExamples,
              'prefersStepByStep': prefersStepByStep,
              'detailLevel': detailLevel,
            },
          ),
        );
    return result.data?['updateLearningProfile'] as Map<String, dynamic>?;
  }

  Future<void> reportIncorrect(String? messageText, String? messageId) async {
    await _ref.read(graphqlClientProvider).mutate(
          MutationOptions(
            document: gql(kReportIncorrect),
            variables: {
              'messageId': messageId,
              'messageText': messageText,
            },
          ),
        );
  }

  void updateLastChatTitle(String? sessionId, String title) {
    if (sessionId == null) return;
    _ref.read(graphqlClientProvider).mutate(
          MutationOptions(
            document: gql(kUpdateChatSessionTitle),
            variables: {
              'sessionId': sessionId,
              'title': title,
            },
          ),
        );
  }
}
