import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_screen_manager.dart';
import 'kids_home_state_provider.dart';

class KidsLessonActions {
  final KidsHomeScreenManager mgr;

  KidsLessonActions(this.mgr);

  void _setState(KidsHomeState s) {
    mgr.ref.read(kidsHomeStateProvider.notifier).apply((_) => s);
  }

  KidsHomeState get _state => mgr.ref.read(kidsHomeStateProvider);

  GraphQLClient _buildKidClient() {
    final auth = mgr.ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<void> claimDailyChest() async {
    final c = _buildKidClient();
    final result =
        await c.mutate(MutationOptions(document: gql(kClaimKidDailyChest)));
    final payload = result.data?['claimKidDailyChest'] as Map<String, dynamic>?;
    if (payload?['success'] == true) {
      HapticFeedback.heavyImpact();
      final s = payload!['summary'] as Map<String, dynamic>?;
      if (s != null) {
        _setState(_state.copyWith(
          dailySummary: Map<String, dynamic>.from(s),
          stars: (s['totalStars'] as num?)?.toInt() ?? _state.stars,
        ));
      }
      ScaffoldMessenger.of(mgr.context).showSnackBar(
        const SnackBar(
            content: Text('You earned bonus stars!'),
            backgroundColor: DesignTokens.success),
      );
    } else {
      final errs = (payload?['errors'] as List?)?.cast<String>() ??
          const ['Try again later'];
      ScaffoldMessenger.of(mgr.context)
          .showSnackBar(SnackBar(content: Text(errs.join(', '))));
    }
  }

  Future<void> fetchLesson(String subjectId, int standard,
      {String? topicId}) async {
    _setState(_state.copyWith(loading: true));
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kFetchKidLesson),
      variables: {
        'subjectId': subjectId,
        'standard': standard,
        'topicId': topicId,
        'language': 'english'
      },
    ));
    if (result.data != null) {
      final d = result.data!['fetchKidLesson'];
      if (d['success'] == true) {
        final currentLesson = d['lesson'];
        final lessonState = d['state'] is Map
            ? Map<String, dynamic>.from(d['state'] as Map)
            : null;
        final quiz =
            (currentLesson?['quiz'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
        _setState(_state.copyWith(
          currentLesson: currentLesson,
          lessonState: lessonState,
          quiz: quiz,
          inQuiz: false,
          quizReviewHint: null,
          selectedStoryChunk: 0,
          loading: false,
        ));
      } else {
        final errs = (d['errors'] as List?)?.cast<String>() ??
            const ['Could not load lesson'];
        ScaffoldMessenger.of(mgr.context)
            .showSnackBar(SnackBar(content: Text(errs.join(', '))));
      }
      await mgr.fetchDailySummary();
      final sid = _state.selectedSubject?['id']?.toString();
      if (sid != null) {
        await mgr.fetchSubjectProgress(
            sid, mgr.ref.read(kidAuthStateProvider).standard);
        await mgr.fetchRoadmap(
            sid, mgr.ref.read(kidAuthStateProvider).standard);
      }
    }
    _setState(_state.copyWith(loading: false));
  }

  Future<void> answerQuiz(int idx) async {
    if (_state.currentLesson == null) return;
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {
        'lessonId': _state.currentLesson!['id'],
        'selectedIndex': idx
      },
    ));
    final payload = result.data?['answerKidQuiz'] as Map<String, dynamic>?;
    final correct = payload?['correct'] == true;
    if (payload?['success'] == false) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ??
          const ['Could not save answer'];
      ScaffoldMessenger.of(mgr.context)
          .showSnackBar(SnackBar(content: Text(errs.join(', '))));
      return;
    }
    _setState(_state.copyWith(
      stars: (payload?['starsEarned'] as num?)?.toInt() ?? _state.stars,
      streak: (payload?['streak'] as num?)?.toInt() ?? _state.streak,
      quizReviewHint: payload?['nextReviewLabel']?.toString(),
      rewardProfile: payload?['rewardProfile'] is Map
          ? Map<String, dynamic>.from(payload!['rewardProfile'] as Map)
          : _state.rewardProfile,
      lessonState: _state.lessonState != null
          ? {
              ..._state.lessonState!,
              'masteryLevel': (payload?['masteryLevel'] as num?)?.toInt() ??
                  _state.lessonState!['masteryLevel'],
              'nextReviewLabel': payload?['nextReviewLabel']?.toString(),
              'quizAttempts':
                  ((_state.lessonState!['quizAttempts'] as num?)?.toInt() ??
                          0) +
                      1,
              'quizCorrect':
                  ((_state.lessonState!['quizCorrect'] as num?)?.toInt() ?? 0) +
                      (correct ? 1 : 0),
              'lastResultCorrect': correct,
            }
          : null,
    ));
    final newBadges = ((payload?['newBadges'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (newBadges.isNotEmpty) {
      final latestBadge = newBadges.first['title']?.toString() ?? 'New badge';
      ScaffoldMessenger.of(mgr.context).showSnackBar(
        SnackBar(
            content: Text('Badge unlocked: $latestBadge'),
            backgroundColor: DesignTokens.success),
      );
    }
    await mgr.fetchDailySummary();
    final sid = _state.selectedSubject?['id']?.toString();
    if (sid != null) {
      await mgr.fetchRoadmap(sid, mgr.ref.read(kidAuthStateProvider).standard);
      await mgr.fetchSubjectProgress(
          sid, mgr.ref.read(kidAuthStateProvider).standard);
    }
  }

  void openRoadmapTopicById(String? topicId) {
    if (topicId == null || topicId.isEmpty) return;
    final match = _state.topics.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['id']?.toString() == topicId,
          orElse: () => null,
        );
    if (match == null) return;
    final sid = _state.selectedSubject?['id']?.toString();
    if (sid == null) return;
    _setState(_state.copyWith(selectedTopic: match));
    fetchLesson(sid, mgr.ref.read(kidAuthStateProvider).standard,
        topicId: topicId);
  }

  Future<void> openJourney(KidAuthState auth) async {
    final sid = _state.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final result = await mgr.context.push('/kids/journey', extra: {
      'subjectId': sid,
      'subjectName': _state.selectedSubject?['name']?.toString() ?? 'Journey',
      'standard': auth.standard,
    });
    if (result is Map) {
      final topicId = result['topicId']?.toString();
      if (topicId != null && topicId.isNotEmpty) {
        openRoadmapTopicById(topicId);
        return;
      }
    }
    await mgr.fetchRewardProfile();
    await mgr.fetchRoadmap(sid, auth.standard);
  }
}
