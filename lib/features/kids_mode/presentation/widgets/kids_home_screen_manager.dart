import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_screen_data.dart';
import 'kids_lesson_actions.dart';

class KidsHomeScreenManager {
  late WidgetRef _refStorage;
  late void Function(VoidCallback) _setStateFn;
  late BuildContext Function() _contextFn;
  late bool Function() _mountedFn;
  final data = KidsHomeScreenData();
  late final KidsLessonActions actions;

  WidgetRef get ref => _refStorage;

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required BuildContext Function() getContext,
    required bool Function() isMounted,
  }) {
    _refStorage = ref;
    _setStateFn = setState;
    _contextFn = getContext;
    _mountedFn = isMounted;
    actions = KidsLessonActions(this);
  }

  bool get mounted => _mountedFn();
  BuildContext get context => _contextFn();
  void setState(VoidCallback fn) => _setStateFn(fn);

  GraphQLClient _buildKidClient() {
    final auth = _refStorage.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<void> fetchSubjects() async {
    data.subjectFetchStarted = true;
    final auth = _refStorage.read(kidAuthStateProvider);
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {
        'standard': auth.standard,
        'educationTrack': auth.educationTrack
      },
    ));
    if (!mounted) return;
    if (result.data != null) {
      data.subjects = ((result.data!['primarySubjects'] as List?) ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      data.fetchedSubjects = true;
      data.subjectFetchStarted = false;
      setState(() {});
      await fetchDailySummary();
      await fetchRewardProfile();
    } else {
      setState(() {
        data.fetchedSubjects = true;
        data.subjectFetchStarted = false;
      });
    }
  }

  Future<void> fetchDailySummary() async {
    final auth = _refStorage.read(kidAuthStateProvider);
    if (!auth.isAuthenticated) return;
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidDailySummary),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted || result.data == null) return;
    final s = result.data!['kidDailySummary'] as Map<String, dynamic>?;
    if (s != null) {
      setState(() {
        data.dailySummary = Map<String, dynamic>.from(s);
        final ts = (data.dailySummary!['totalStars'] as num?)?.toInt();
        if (ts != null) data.stars = ts;
      });
    }
  }

  Future<void> fetchRewardProfile() async {
    final result = await _buildKidClient().query(
      QueryOptions(
          document: gql(kKidRewardProfile),
          fetchPolicy: FetchPolicy.networkOnly),
    );
    if (!mounted) return;
    final profile = result.data?['kidRewardProfile'];
    setState(() {
      data.rewardProfile =
          profile is Map ? Map<String, dynamic>.from(profile) : null;
    });
  }

  Future<void> fetchTopics(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimaryTopics),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    setState(() {
      data.topics = ((result.data?['primaryTopics'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (data.topics.isEmpty) {
        data.selectedTopic = null;
      } else if (data.selectedTopic == null ||
          !data.topics.any((t) => t['id'] == data.selectedTopic?['id'])) {
        data.selectedTopic = data.topics.first;
      }
    });
  }

  Future<void> fetchSubjectProgress(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidProgress),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    final progress = result.data?['kidProgress'];
    setState(() {
      data.subjectProgress =
          progress is Map ? Map<String, dynamic>.from(progress) : null;
    });
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
    if (!mounted) return;
    final roadmap = roadmapResult.data?['kidSubjectRoadmap'];
    setState(() {
      data.roadmapSummary = roadmap is Map && roadmap['summary'] is Map
          ? Map<String, dynamic>.from(roadmap['summary'] as Map)
          : null;
      data.topicRoadmap =
          ((roadmap is Map ? roadmap['topics'] : null) as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      data.reviewQueue =
          ((reviewResult.data?['kidReviewQueue'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
    });
    await fetchRewardProfile();
  }
}
