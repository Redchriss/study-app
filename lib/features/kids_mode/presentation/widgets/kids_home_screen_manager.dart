import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_screen_data.dart';

class KidsHomeScreenManager {
  late WidgetRef _ref;
  late void Function(VoidCallback) _setStateFn;
  late BuildContext Function() _contextFn;
  late bool Function() _mountedFn;
  final data = KidsHomeScreenData();

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required BuildContext Function() getContext,
    required bool Function() isMounted,
  }) {
    _ref = ref;
    _setStateFn = setState;
    _contextFn = getContext;
    _mountedFn = isMounted;
  }

  bool get mounted => _mountedFn();
  BuildContext get context => _contextFn();
  void setState(VoidCallback fn) => _setStateFn(fn);

  GraphQLClient _buildKidClient() {
    final auth = _ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<void> fetchSubjects() async {
    data.subjectFetchStarted = true;
    final auth = _ref.read(kidAuthStateProvider);
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {'standard': auth.standard, 'educationTrack': auth.educationTrack},
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
    final auth = _ref.read(kidAuthStateProvider);
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
      QueryOptions(document: gql(kKidRewardProfile), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (!mounted) return;
    final profile = result.data?['kidRewardProfile'];
    setState(() {
      data.rewardProfile = profile is Map ? Map<String, dynamic>.from(profile) : null;
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
      } else if (data.selectedTopic == null || !data.topics.any((t) => t['id'] == data.selectedTopic?['id'])) {
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
      data.subjectProgress = progress is Map ? Map<String, dynamic>.from(progress) : null;
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
      data.topicRoadmap = ((roadmap is Map ? roadmap['topics'] : null) as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      data.reviewQueue = ((reviewResult.data?['kidReviewQueue'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    });
    await fetchRewardProfile();
  }

  Future<void> claimDailyChest() async {
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(document: gql(kClaimKidDailyChest)));
    final payload = result.data?['claimKidDailyChest'] as Map<String, dynamic>?;
    if (payload?['success'] == true && mounted) {
      HapticFeedback.heavyImpact();
      final s = payload!['summary'] as Map<String, dynamic>?;
      if (s != null) {
        setState(() {
          data.dailySummary = Map<String, dynamic>.from(s);
          final ts = (data.dailySummary!['totalStars'] as num?)?.toInt();
          if (ts != null) data.stars = ts;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You earned bonus stars!'), backgroundColor: DesignTokens.success),
      );
    } else if (mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ?? const ['Try again later'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
    }
  }

  Future<void> fetchLesson(String subjectId, int standard, {String? topicId}) async {
    setState(() => data.loading = true);
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kFetchKidLesson),
      variables: {'subjectId': subjectId, 'standard': standard, 'topicId': topicId, 'language': 'english'},
    ));
    if (!mounted) return;
    if (result.data != null) {
      final d = result.data!['fetchKidLesson'];
      if (d['success'] == true) {
        setState(() {
          data.currentLesson = d['lesson'];
          data.lessonState = d['state'] is Map ? Map<String, dynamic>.from(d['state'] as Map) : null;
          data.quiz = (data.currentLesson?['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          data.inQuiz = false;
          data.quizReviewHint = null;
          data.selectedStoryChunk = 0;
          data.loading = false;
        });
      } else {
        final errs = (d['errors'] as List?)?.cast<String>() ?? const ['Could not load lesson'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
      }
      await fetchDailySummary();
      final sid = data.selectedSubject?['id']?.toString();
      if (sid != null) {
        await fetchSubjectProgress(sid, _ref.read(kidAuthStateProvider).standard);
        await fetchRoadmap(sid, _ref.read(kidAuthStateProvider).standard);
      }
    }
    setState(() => data.loading = false);
  }

  Future<void> answerQuiz(int idx) async {
    if (data.currentLesson == null) return;
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {'lessonId': data.currentLesson!['id'], 'selectedIndex': idx},
    ));
    final payload = result.data?['answerKidQuiz'] as Map<String, dynamic>?;
    final correct = payload?['correct'] == true;
    if (payload?['success'] == false && mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ?? const ['Could not save answer'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
      return;
    }
    if (!mounted) return;
    setState(() {
      data.stars = (payload?['starsEarned'] as num?)?.toInt() ?? data.stars;
      data.streak = (payload?['streak'] as num?)?.toInt() ?? data.streak;
      data.quizReviewHint = payload?['nextReviewLabel']?.toString();
      if (payload?['rewardProfile'] is Map) {
        data.rewardProfile = Map<String, dynamic>.from(payload!['rewardProfile'] as Map);
      }
      if (data.lessonState != null) {
        data.lessonState = {
          ...data.lessonState!,
          'masteryLevel': (payload?['masteryLevel'] as num?)?.toInt() ?? data.lessonState!['masteryLevel'],
          'nextReviewLabel': payload?['nextReviewLabel']?.toString(),
          'quizAttempts': ((data.lessonState!['quizAttempts'] as num?)?.toInt() ?? 0) + 1,
          'quizCorrect': ((data.lessonState!['quizCorrect'] as num?)?.toInt() ?? 0) + (correct ? 1 : 0),
          'lastResultCorrect': correct,
        };
      }
    });
    final newBadges = ((payload?['newBadges'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (mounted && newBadges.isNotEmpty) {
      final latestBadge = newBadges.first['title']?.toString() ?? 'New badge';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Badge unlocked: $latestBadge'), backgroundColor: DesignTokens.success),
      );
    }
    await fetchDailySummary();
    final sid = data.selectedSubject?['id']?.toString();
    if (sid != null) {
      await fetchRoadmap(sid, _ref.read(kidAuthStateProvider).standard);
      await fetchSubjectProgress(sid, _ref.read(kidAuthStateProvider).standard);
    }
  }

  void openRoadmapTopicById(String? topicId) {
    if (topicId == null || topicId.isEmpty) return;
    final match = data.topics.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['id']?.toString() == topicId,
          orElse: () => null,
        );
    if (match == null) return;
    final sid = data.selectedSubject?['id']?.toString();
    if (sid == null) return;
    setState(() => data.selectedTopic = match);
    fetchLesson(sid, _ref.read(kidAuthStateProvider).standard, topicId: topicId);
  }

  Future<void> openJourney(KidAuthState auth) async {
    final sid = data.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final result = await context.push('/kids/journey', extra: {
      'subjectId': sid,
      'subjectName': data.selectedSubject?['name']?.toString() ?? 'Journey',
      'standard': auth.standard,
    });
    if (!mounted) return;
    if (result is Map) {
      final topicId = result['topicId']?.toString();
      if (topicId != null && topicId.isNotEmpty) {
        openRoadmapTopicById(topicId);
        return;
      }
    }
    await fetchRewardProfile();
    await fetchRoadmap(sid, auth.standard);
  }
}
