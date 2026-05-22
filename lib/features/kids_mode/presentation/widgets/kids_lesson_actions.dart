import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_screen_manager.dart';

class KidsLessonActions {
  final KidsHomeScreenManager mgr;

  KidsLessonActions(this.mgr);

  Future<void> claimDailyChest() async {
    final c = _buildKidClient();
    final result =
        await c.mutate(MutationOptions(document: gql(kClaimKidDailyChest)));
    final payload = result.data?['claimKidDailyChest'] as Map<String, dynamic>?;
    if (payload?['success'] == true && mgr.mounted) {
      HapticFeedback.heavyImpact();
      final s = payload!['summary'] as Map<String, dynamic>?;
      if (s != null) {
        mgr.setState(() {
          mgr.data.dailySummary = Map<String, dynamic>.from(s);
          final ts = (mgr.data.dailySummary!['totalStars'] as num?)?.toInt();
          if (ts != null) mgr.data.stars = ts;
        });
      }
      ScaffoldMessenger.of(mgr.context).showSnackBar(
        const SnackBar(
            content: Text('You earned bonus stars!'),
            backgroundColor: DesignTokens.success),
      );
    } else if (mgr.mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ??
          const ['Try again later'];
      ScaffoldMessenger.of(mgr.context)
          .showSnackBar(SnackBar(content: Text(errs.join(', '))));
    }
  }

  Future<void> fetchLesson(String subjectId, int standard,
      {String? topicId}) async {
    mgr.setState(() => mgr.data.loading = true);
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
    if (!mgr.mounted) return;
    if (result.data != null) {
      final d = result.data!['fetchKidLesson'];
      if (d['success'] == true) {
        mgr.setState(() {
          mgr.data.currentLesson = d['lesson'];
          mgr.data.lessonState = d['state'] is Map
              ? Map<String, dynamic>.from(d['state'] as Map)
              : null;
          mgr.data.quiz = (mgr.data.currentLesson?['quiz'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          mgr.data.inQuiz = false;
          mgr.data.quizReviewHint = null;
          mgr.data.selectedStoryChunk = 0;
          mgr.data.loading = false;
        });
      } else {
        final errs = (d['errors'] as List?)?.cast<String>() ??
            const ['Could not load lesson'];
        ScaffoldMessenger.of(mgr.context)
            .showSnackBar(SnackBar(content: Text(errs.join(', '))));
      }
      await mgr.fetchDailySummary();
      final sid = mgr.data.selectedSubject?['id']?.toString();
      if (sid != null) {
        await mgr.fetchSubjectProgress(
            sid, mgr.ref.read(kidAuthStateProvider).standard);
        await mgr.fetchRoadmap(
            sid, mgr.ref.read(kidAuthStateProvider).standard);
      }
    }
    mgr.setState(() => mgr.data.loading = false);
  }

  Future<void> answerQuiz(int idx) async {
    if (mgr.data.currentLesson == null) return;
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {
        'lessonId': mgr.data.currentLesson!['id'],
        'selectedIndex': idx
      },
    ));
    final payload = result.data?['answerKidQuiz'] as Map<String, dynamic>?;
    final correct = payload?['correct'] == true;
    if (payload?['success'] == false && mgr.mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ??
          const ['Could not save answer'];
      ScaffoldMessenger.of(mgr.context)
          .showSnackBar(SnackBar(content: Text(errs.join(', '))));
      return;
    }
    if (!mgr.mounted) return;
    mgr.setState(() {
      mgr.data.stars =
          (payload?['starsEarned'] as num?)?.toInt() ?? mgr.data.stars;
      mgr.data.streak =
          (payload?['streak'] as num?)?.toInt() ?? mgr.data.streak;
      mgr.data.quizReviewHint = payload?['nextReviewLabel']?.toString();
      if (payload?['rewardProfile'] is Map) {
        mgr.data.rewardProfile =
            Map<String, dynamic>.from(payload!['rewardProfile'] as Map);
      }
      if (mgr.data.lessonState != null) {
        mgr.data.lessonState = {
          ...mgr.data.lessonState!,
          'masteryLevel': (payload?['masteryLevel'] as num?)?.toInt() ??
              mgr.data.lessonState!['masteryLevel'],
          'nextReviewLabel': payload?['nextReviewLabel']?.toString(),
          'quizAttempts':
              ((mgr.data.lessonState!['quizAttempts'] as num?)?.toInt() ?? 0) +
                  1,
          'quizCorrect':
              ((mgr.data.lessonState!['quizCorrect'] as num?)?.toInt() ?? 0) +
                  (correct ? 1 : 0),
          'lastResultCorrect': correct,
        };
      }
    });
    final newBadges = ((payload?['newBadges'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (mgr.mounted && newBadges.isNotEmpty) {
      final latestBadge = newBadges.first['title']?.toString() ?? 'New badge';
      ScaffoldMessenger.of(mgr.context).showSnackBar(
        SnackBar(
            content: Text('Badge unlocked: $latestBadge'),
            backgroundColor: DesignTokens.success),
      );
    }
    await mgr.fetchDailySummary();
    final sid = mgr.data.selectedSubject?['id']?.toString();
    if (sid != null) {
      await mgr.fetchRoadmap(sid, mgr.ref.read(kidAuthStateProvider).standard);
      await mgr.fetchSubjectProgress(
          sid, mgr.ref.read(kidAuthStateProvider).standard);
    }
  }

  void openRoadmapTopicById(String? topicId) {
    if (topicId == null || topicId.isEmpty) return;
    final match = mgr.data.topics.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['id']?.toString() == topicId,
          orElse: () => null,
        );
    if (match == null) return;
    final sid = mgr.data.selectedSubject?['id']?.toString();
    if (sid == null) return;
    mgr.setState(() => mgr.data.selectedTopic = match);
    fetchLesson(sid, mgr.ref.read(kidAuthStateProvider).standard,
        topicId: topicId);
  }

  Future<void> openJourney(KidAuthState auth) async {
    final sid = mgr.data.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final result = await mgr.context.push('/kids/journey', extra: {
      'subjectId': sid,
      'subjectName': mgr.data.selectedSubject?['name']?.toString() ?? 'Journey',
      'standard': auth.standard,
    });
    if (!mgr.mounted) return;
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

  GraphQLClient _buildKidClient() {
    final auth = mgr.ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }
}
