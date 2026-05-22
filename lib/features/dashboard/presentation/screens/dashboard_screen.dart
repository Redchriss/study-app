import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/dashboard_hero_header.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_focus_coach_card.dart';
import '../widgets/dashboard_adaptive_plan_card.dart';
import '../widgets/dashboard_progress_snapshot_card.dart';
import '../widgets/dashboard_material_cards.dart';
import '../widgets/dashboard_loading.dart';

List<String> _toStringList(dynamic raw) => ((raw as List?) ?? const [])
    .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
    .where((s) => s.trim().isNotEmpty)
    .cast<String>()
    .toList();

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final StudyProgressStore _progressStore = StudyProgressStore();
  final RetentionService _retention = RetentionService();
  late Future<QueryResult> _adaptivePlanFuture;
  String? _lastReminderTopic;

  @override
  void initState() {
    super.initState();
    _adaptivePlanFuture = _loadAdaptiveStudyPlan();
  }

  Future<QueryResult> _loadAdaptiveStudyPlan() {
    return ref.read(graphqlClientProvider).query(
      QueryOptions(document: gql(kAdaptiveStudyPlan), fetchPolicy: FetchPolicy.networkOnly),
    );
  }

  Future<void> _refreshDashboard(Refetch? refetch) async {
    refetch?.call();
    setState(() => _adaptivePlanFuture = _loadAdaptiveStudyPlan());
  }

  void _scheduleWeakTopicReminder(List<String> weakestTopics) {
    if (weakestTopics.isEmpty) return;
    final nextTopic = weakestTopics.first;
    if (_lastReminderTopic == nextTopic) return;
    _lastReminderTopic = nextTopic;
    unawaited(_retention.refreshStudyReminder(weakTopic: nextTopic));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(document: gql(kDashboard)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: DashboardLoading());
        if (result.hasException) {
          return Scaffold(
            body: ErrorState(
              message: graphQLErrorMessage(result.exception, 'Could not load dashboard.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final me = result.data?['me'];
        final profile = me?['profile'];
        final recentMaterials = (result.data?['recentMaterials'] as List?) ?? [];
        final latestMaterialProgress = StudyMaterialProgress.fromGraphQL(
          result.data?['latestMaterialProgress'] is Map
              ? Map<String, dynamic>.from(result.data!['latestMaterialProgress'] as Map)
              : null,
        );
        final snap = result.data?['progressSnapshot'];
        final circles = (result.data?['myCircles'] as List?) ?? [];
        final learningProfile = result.data?['learningProfile'] as Map<String, dynamic>?;

        final name = me?['username'] as String? ?? 'Student';
        final educationLevel = profile?['educationLevel']?.toString() ?? 'secondary';
        final streak = (profile?['studyStreak'] as num?)?.toInt() ?? 0;
        final points = (profile?['studyPoints'] as num?)?.toInt() ?? 0;
        final credits = (profile?['aiCredits'] as num?)?.toInt() ?? 0;

        final weakestTopics = _toStringList(snap?['weakestTopics']);
        final strongestTopics = _toStringList(snap?['strongestTopics']);
        final strugglingTopics = ((learningProfile?['topicsStruggling'] as List?) ?? const [])
            .map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        final masteredTopics = ((learningProfile?['topicsMastered'] as List?) ?? const [])
            .map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();

        _scheduleWeakTopicReminder(weakestTopics);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _refreshDashboard(refetch),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeroHeader(
                    name: name,
                    educationLevel: educationLevel,
                    streak: streak,
                    points: points,
                    credits: credits,
                    dark: dark,
                    onNotification: () => context.go('/notifications'),
                    onAiTutor: () => context.push('/ai-tutor'),
                  ),
                ),

                // Continue Studying
                if (latestMaterialProgress != null)
                  SliverToBoxAdapter(child: DashboardContinueStudyCard(progress: latestMaterialProgress).animate().fadeIn(delay: 200.ms))
                else
                  SliverToBoxAdapter(
                    child: FutureBuilder<StudyMaterialProgress?>(
                      future: _progressStore.loadLastMaterial(),
                      builder: (_, snapshot) {
                        final saved = snapshot.data;
                        if (saved == null) return const SizedBox.shrink();
                        return DashboardContinueStudyCard(progress: saved).animate().fadeIn(delay: 200.ms);
                      },
                    ),
                  ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: DesignTokens.spSm),
                        DashboardQuickActions(educationLevel: educationLevel, circlesCount: circles.length),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),

                // Focus Coach
                if (weakestTopics.isNotEmpty || strugglingTopics.isNotEmpty || masteredTopics.isNotEmpty)
                  SliverToBoxAdapter(
                    child: DashboardFocusCoachCard(
                      weakestTopics: weakestTopics,
                      strongestTopics: strongestTopics,
                      strugglingTopics: strugglingTopics,
                      masteredTopics: masteredTopics,
                    ).animate().fadeIn(delay: 350.ms),
                  ),

                // Adaptive Study Plan
                SliverToBoxAdapter(
                  child: FutureBuilder<QueryResult>(
                    future: _adaptivePlanFuture,
                    builder: (_, snapshot) {
                      final plan = snapshot.data?.data?['adaptiveStudyPlan'];
                      if (plan is! Map) return const SizedBox.shrink();
                      final tasks = ((plan['tasksJson'] as List?) ?? const []).whereType<Map>().toList();
                      return DashboardAdaptivePlanCard(
                        planSummary: plan['planSummary']?.toString() ?? '',
                        tasks: tasks,
                        dark: dark,
                      ).animate().fadeIn(delay: 400.ms);
                    },
                  ),
                ),

                // Progress Snapshot
                if (snap?['hasData'] == true)
                  SliverToBoxAdapter(
                    child: DashboardProgressSnapshotCard(
                      snap: snap,
                      strongestTopics: strongestTopics,
                      weakestTopics: weakestTopics,
                      dark: dark,
                    ).animate().fadeIn(delay: 450.ms),
                  ),

                // Recent Materials
                if (recentMaterials.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spSm),
                      child: SectionHeader(title: 'Recent Materials', actionLabel: 'See all', onAction: () => context.push('/materials')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(DesignTokens.spMd, 0, DesignTokens.spMd, 0),
                        itemCount: recentMaterials.length,
                        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spSm),
                        itemBuilder: (_, i) {
                          final m = recentMaterials[i];
                          return DashboardRecentMaterialCard(
                            material: m,
                            dark: dark,
                            onTap: () => context.push('/materials/${m['slug']}'),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spXxl * 2)),
              ],
            ),
          ),
        );
      },
    );
  }

}
