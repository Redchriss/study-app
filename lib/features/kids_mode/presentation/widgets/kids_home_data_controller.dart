import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';

class KidsHomeDataController {
  final WidgetRef ref;

  KidsHomeDataController(this.ref);

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<Map<String, dynamic>?> fetchDailySummary() async {
    final auth = ref.read(kidAuthStateProvider);
    if (!auth.isAuthenticated) return null;
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidDailySummary),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    return result.data?['kidDailySummary'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> fetchRewardProfile() async {
    final result = await _buildKidClient().query(
      QueryOptions(document: gql(kKidRewardProfile), fetchPolicy: FetchPolicy.networkOnly),
    );
    final profile = result.data?['kidRewardProfile'];
    return profile is Map ? Map<String, dynamic>.from(profile) : null;
  }

  Future<List<Map<String, dynamic>>> fetchSubjects(String standard, String educationTrack) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {'standard': standard, 'educationTrack': educationTrack},
    ));
    final list = ((result.data?['primarySubjects'] as List?) ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchTopics(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimaryTopics),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    return ((result.data?['primaryTopics'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchSubjectProgress(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidProgress),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final progress = result.data?['kidProgress'];
    return progress is Map ? Map<String, dynamic>.from(progress) : null;
  }

  Future<Map<String, dynamic>?> fetchRoadmapSummary(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidSubjectRoadmap),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final roadmap = result.data?['kidSubjectRoadmap'];
    return roadmap is Map && roadmap['summary'] is Map
        ? Map<String, dynamic>.from(roadmap['summary'] as Map)
        : null;
  }

  Future<List<Map<String, dynamic>>> fetchTopicRoadmap(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidSubjectRoadmap),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final roadmap = result.data?['kidSubjectRoadmap'];
    return ((roadmap is Map ? roadmap['topics'] : null) as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchReviewQueue() async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidReviewQueue),
      variables: const {'limit': 4},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    return ((result.data?['kidReviewQueue'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchLesson(String subjectId, int standard, {String? topicId}) async {
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kFetchKidLesson),
      variables: {'subjectId': subjectId, 'standard': standard, 'topicId': topicId, 'language': 'english'},
    ));
    final data = result.data?['fetchKidLesson'];
    if (data?['success'] == true) {
      return {
        'lesson': data['lesson'],
        'state': data['state'] is Map ? Map<String, dynamic>.from(data['state'] as Map) : null,
      };
    }
    return null;
  }

  Future<Map<String, dynamic>?> claimDailyChest() async {
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(document: gql(kClaimKidDailyChest)));
    final payload = result.data?['claimKidDailyChest'] as Map<String, dynamic>?;
    if (payload?['success'] == true) {
      return payload;
    }
    return payload;
  }

  Future<Map<String, dynamic>?> answerQuiz(String lessonId, int selectedIndex) async {
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {'lessonId': lessonId, 'selectedIndex': selectedIndex},
    ));
    return result.data?['answerKidQuiz'] as Map<String, dynamic>?;
  }
}
