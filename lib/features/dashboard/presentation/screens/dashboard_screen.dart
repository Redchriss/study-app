import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/dashboard_data.dart';
import '../widgets/dashboard_hero_header.dart';
import '../widgets/dashboard_continue_study_panel.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recommendations_panel.dart';
import '../widgets/dashboard_recent_panel.dart';
import '../widgets/dashboard_onboarding_card.dart';
import '../widgets/dashboard_loading.dart';
import '../widgets/dashboard_suggestions_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Query(
      options: QueryOptions(document: gql(kDashboard)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const DashboardLoading();

        if (result.hasException) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async => refetch?.call(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DashboardHeroHeader(
                      name: 'Student',
                      educationLevel: 'secondary',
                      streak: 0,
                      points: 0,
                      credits: 0,
                      dark: dark,
                      onNotification: () =>
                          context.push('/dashboard/notifications'),
                      onAiTutor: () => context.push('/ai-tutor'),
                    ),
                  ),
                  SliverFillRemaining(
                    child: ErrorState(
                      message: graphQLErrorMessage(
                          result.exception, 'Could not load dashboard.'),
                      onRetry: () => refetch?.call(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = DashboardData.fromGraphQL(result.data);
        unawaited(RetentionService()
            .refreshStudyReminder(weakTopic: data.focusTopic));

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeroHeader(
                    name: data.name,
                    educationLevel: data.educationLevel,
                    streak: data.streak,
                    points: data.points,
                    credits: data.credits,
                    dark: dark,
                    onNotification: () =>
                        context.push('/dashboard/notifications'),
                    onAiTutor: () => context.push('/ai-tutor'),
                    dailyProgress: data.dailyProgress,
                    dailyGoal: DashboardData.dailyQuestionGoal,
                    showDailyGoal: data.streak > 0 || data.hasProgressData,
                  ),
                ),
                if (data.isFirstTime)
                  const SliverToBoxAdapter(child: DashboardOnboardingCard())
                else
                  SliverToBoxAdapter(
                    child: DashboardContinueStudyPanel(
                        liveProgress: data.latestProgress),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(DesignTokens.spMd, 0,
                        DesignTokens.spMd, DesignTokens.spMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: DesignTokens.spSm),
                        const DashboardQuickActions(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: DashboardSuggestionsPanel()),
                if (!data.isFirstTime &&
                    (data.focusTopic.isNotEmpty || data.hasProgressData))
                  SliverToBoxAdapter(
                    child: DashboardRecommendationsPanel(data: data),
                  ),
                if (data.recentMaterials.isNotEmpty)
                  SliverToBoxAdapter(
                    child:
                        DashboardRecentPanel(materials: data.recentMaterials),
                  ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spXxl * 2)),
              ],
            ),
          ),
        );
      },
    );
  }
}
