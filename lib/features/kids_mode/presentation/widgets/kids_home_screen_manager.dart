import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_state_provider.dart';
import 'kids_lesson_actions.dart';

class KidsHomeScreenManager {
  final WidgetRef ref;
  late final KidsLessonActions actions;
  BuildContext Function() _contextFn = () => throw UnimplementedError();
  bool Function() _mountedFn = () => true;

  KidsHomeScreenManager(this.ref) {
    actions = KidsLessonActions(this);
  }

  void attach({
    required BuildContext Function() getContext,
    required bool Function() isMounted,
  }) {
    _contextFn = getContext;
    _mountedFn = isMounted;
  }

  BuildContext get context => _contextFn();
  bool get mounted => _mountedFn();

  KidsHomeState get state => ref.read(kidsHomeStateProvider);

  void _update(KidsHomeState Function(KidsHomeState) cb) {
    ref.read(kidsHomeStateProvider.notifier).apply(cb);
  }

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<void> fetchSubjects() async {
    _update((s) => s.copyWith(subjectFetchStarted: true));
    final auth = ref.read(kidAuthStateProvider);
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {
        'standard': auth.standard,
        'educationTrack': auth.educationTrack
      },
    ));
    if (result.data != null) {
      final subjects = ((result.data!['primarySubjects'] as List?) ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      _update((s) => s.copyWith(
          subjects: subjects,
          fetchedSubjects: true,
          subjectFetchStarted: false));
      await fetchDailySummary();
      await fetchRewardProfile();
    } else {
      _update(
          (s) => s.copyWith(fetchedSubjects: true, subjectFetchStarted: false));
    }
  }

  Future<void> fetchDailySummary() async {
    final auth = ref.read(kidAuthStateProvider);
    if (!auth.isAuthenticated) return;
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidDailySummary),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.data == null) return;
    final s = result.data!['kidDailySummary'] as Map<String, dynamic>?;
    if (s != null) {
      _update((prev) {
        final dailySummary = Map<String, dynamic>.from(s);
        final stars =
            (dailySummary['totalStars'] as num?)?.toInt() ?? prev.stars;
        return prev.copyWith(dailySummary: dailySummary, stars: stars);
      });
    }
  }

  Future<void> fetchRewardProfile() async {
    final result = await _buildKidClient().query(
      QueryOptions(
          document: gql(kKidRewardProfile),
          fetchPolicy: FetchPolicy.networkOnly),
    );
    final profile = result.data?['kidRewardProfile'];
    if (profile is Map) {
      _update(
          (s) => s.copyWith(rewardProfile: Map<String, dynamic>.from(profile)));
    }
  }

  Future<void> fetchTopics(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimaryTopics),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final topics = ((result.data?['primaryTopics'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _update((s) {
      var selectedTopic = s.selectedTopic;
      if (topics.isEmpty) {
        selectedTopic = null;
      } else if (selectedTopic == null ||
          !topics.any((t) => t['id'] == selectedTopic!['id'])) {
        selectedTopic = topics.first;
      }
      return s.copyWith(topics: topics, selectedTopic: selectedTopic);
    });
  }

  Future<void> fetchSubjectProgress(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidProgress),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final progress = result.data?['kidProgress'];
    if (progress is Map) {
      _update((s) =>
          s.copyWith(subjectProgress: Map<String, dynamic>.from(progress)));
    }
  }

  Future<void> fetchRoadmap(String subjectId, int standard) async {
    final c = _buildKidClient();
    final roadmapResult = await c.query(QueryOptions(
      document: gql(kKidSubjectRoadmap),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final reviewResult = await c.query(QueryOptions(
      document: gql(kKidReviewQueue),
      variables: const {'limit': 4},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final roadmap = roadmapResult.data?['kidSubjectRoadmap'];
    _update((s) {
      final roadmapSummary = roadmap is Map && roadmap['summary'] is Map
          ? Map<String, dynamic>.from(roadmap['summary'] as Map)
          : null;
      final topicRoadmap =
          ((roadmap is Map ? roadmap['topics'] : null) as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      final reviewQueue =
          ((reviewResult.data?['kidReviewQueue'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      return s.copyWith(
        roadmapSummary: roadmapSummary,
        topicRoadmap: topicRoadmap,
        reviewQueue: reviewQueue,
      );
    });
    await fetchRewardProfile();
  }
}
