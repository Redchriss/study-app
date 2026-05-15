import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

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
          QueryOptions(
              document: gql(kAdaptiveStudyPlan),
              fetchPolicy: FetchPolicy.networkOnly),
        );
  }

  Future<void> _refreshDashboard(Refetch? refetch) async {
    refetch?.call();
    setState(() {
      _adaptivePlanFuture = _loadAdaptiveStudyPlan();
    });
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
        if (result.isLoading) {
          return Scaffold(body: _buildLoadingShimmer(dark));
        }
        if (result.hasException) {
          return Scaffold(
            body: ErrorState(
              message: result.exception?.graphqlErrors.firstOrNull?.message ??
                  'Could not load dashboard.',
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final me = result.data?['me'];
        final profile = me?['profile'];
        final recentMaterials = (result.data?['recentMaterials'] as List?) ?? [];
        final latestMaterialProgress = StudyMaterialProgress.fromGraphQL(
          result.data?['latestMaterialProgress'] is Map
              ? Map<String, dynamic>.from(
                  result.data!['latestMaterialProgress'] as Map)
              : null,
        );
        final snap = result.data?['progressSnapshot'];
        final circles = (result.data?['myCircles'] as List?) ?? [];
        final learningProfile =
            result.data?['learningProfile'] as Map<String, dynamic>?;
        final name = me?['username'] as String? ?? 'Student';
        final educationLevel =
            profile?['educationLevel']?.toString() ?? 'secondary';
        final streak = (profile?['studyStreak'] as num?)?.toInt() ?? 0;
        final points = (profile?['studyPoints'] as num?)?.toInt() ?? 0;
        final credits = (profile?['aiCredits'] as num?)?.toInt() ?? 0;

        final weakestTopics = ((snap?['weakestTopics'] as List?) ?? const [])
            .map((item) =>
                item is Map ? (item['name']?.toString() ?? '') : item.toString())
            .where((item) => item.trim().isNotEmpty)
            .cast<String>()
            .toList();
        _scheduleWeakTopicReminder(weakestTopics);

        final strongestTopics =
            ((snap?['strongestTopics'] as List?) ?? const [])
                .map((item) => item is Map
                    ? (item['name']?.toString() ?? '')
                    : item.toString())
                .where((item) => item.trim().isNotEmpty)
                .cast<String>()
                .toList();
        final strugglingTopics =
            ((learningProfile?['topicsStruggling'] as List?) ?? const [])
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList();
        final masteredTopics =
            ((learningProfile?['topicsMastered'] as List?) ?? const [])
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _refreshDashboard(refetch),
            child: CustomScrollView(
              slivers: [
                // ── Hero Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    name: name,
                    educationLevel: educationLevel,
                    streak: streak,
                    points: points,
                    credits: credits,
                    dark: dark,
                    onNotification: () => context.go('/notifications'),
                    onAiTutor: () => context.go('/ai-tutor'),
                  ),
                ),

                // ── Continue Studying ────────────────────────────────────
                if (latestMaterialProgress != null)
                  SliverToBoxAdapter(
                    child: _ContinueStudyCard(
                        progress: latestMaterialProgress).animate().fadeIn(delay: 200.ms),
                  )
                else
                  SliverToBoxAdapter(
                    child: FutureBuilder<StudyMaterialProgress?>(
                      future: _progressStore.loadLastMaterial(),
                      builder: (context, snapshot) {
                        final saved = snapshot.data;
                        if (saved == null) return const SizedBox.shrink();
                        return _ContinueStudyCard(progress: saved)
                            .animate()
                            .fadeIn(delay: 200.ms);
                      },
                    ),
                  ),

                // ── Quick Actions ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: DesignTokens.spSm),
                        _QuickActionsGrid(
                          educationLevel: educationLevel,
                          circlesCount: circles.length,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),

                // ── Focus Coach ───────────────────────────────────────────
                if (weakestTopics.isNotEmpty ||
                    strugglingTopics.isNotEmpty ||
                    masteredTopics.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FocusCoachCard(
                      weakestTopics: weakestTopics,
                      strongestTopics: strongestTopics,
                      strugglingTopics: strugglingTopics,
                      masteredTopics: masteredTopics,
                    ).animate().fadeIn(delay: 350.ms),
                  ),

                // ── Adaptive Study Plan ───────────────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<QueryResult>(
                    future: _adaptivePlanFuture,
                    builder: (context, snapshot) {
                      final plan =
                          snapshot.data?.data?['adaptiveStudyPlan'];
                      if (plan is! Map) return const SizedBox.shrink();
                      final tasks = ((plan['tasksJson'] as List?) ?? const [])
                          .whereType<Map>()
                          .toList();
                      return _AdaptivePlanCard(
                        planSummary: plan['planSummary']?.toString() ?? '',
                        tasks: tasks,
                        dark: dark,
                      ).animate().fadeIn(delay: 400.ms);
                    },
                  ),
                ),

                // ── Progress Snapshot ─────────────────────────────────────
                if (snap?['hasData'] == true)
                  SliverToBoxAdapter(
                    child: _ProgressSnapshotCard(
                      snap: snap,
                      strongestTopics: strongestTopics,
                      weakestTopics: weakestTopics,
                      dark: dark,
                    ).animate().fadeIn(delay: 450.ms),
                  ),

                // ── Recent Materials ──────────────────────────────────────
                if (recentMaterials.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spSm),
                      child: SectionHeader(
                        title: 'Recent Materials',
                        actionLabel: 'See all',
                        onAction: () => context.go('/materials'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                            DesignTokens.spMd, 0, DesignTokens.spMd, 0),
                        itemCount: recentMaterials.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: DesignTokens.spSm),
                        itemBuilder: (_, i) {
                          final m = recentMaterials[i];
                          return _RecentMaterialCard(
                            material: m,
                            dark: dark,
                            onTap: () =>
                                context.go('/materials/${m['slug']}'),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spXxl * 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer(bool dark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const ShimmerBox(height: 220, radius: 0),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const ShimmerBox(height: 90, radius: 16),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(child: ShimmerBox(height: 90, radius: 16)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 90, radius: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ShimmerBox(height: 120, radius: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String name;
  final String educationLevel;
  final int streak;
  final int points;
  final int credits;
  final bool dark;
  final VoidCallback onNotification;
  final VoidCallback onAiTutor;

  const _HeroHeader({
    required this.name,
    required this.educationLevel,
    required this.streak,
    required this.points,
    required this.credits,
    required this.dark,
    required this.onNotification,
    required this.onAiTutor,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _levelLabel {
    switch (educationLevel.toLowerCase()) {
      case 'primary':
        return 'Primary student';
      case 'tertiary':
        return 'University student';
      default:
        return 'Secondary student';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _levelLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 24),
                    onPressed: onNotification,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  _HeroStat(
                    value: streak.toString(),
                    label: 'Day Streak',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF9800),
                    iconBg: const Color(0x33FF9800),
                  ),
                  const SizedBox(width: 10),
                  _HeroStat(
                    value: points.toString(),
                    label: 'Study Points',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFFD700),
                    iconBg: const Color(0x33FFD700),
                  ),
                  const SizedBox(width: 10),
                  _HeroStat(
                    value: credits.toString(),
                    label: 'AI Credits',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF69F0AE),
                    iconBg: const Color(0x3369F0AE),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // AI Tutor CTA
            GestureDetector(
              onTap: onAiTutor,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF69F0AE), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ask AI Tutor anything...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Curved bottom
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: dark
                    ? DesignTokens.darkBackground
                    : DesignTokens.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color iconBg;
  const _HeroStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final String educationLevel;
  final int circlesCount;
  const _QuickActionsGrid(
      {required this.educationLevel, required this.circlesCount});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _ActionTile(
            icon: Icons.document_scanner_rounded,
            label: 'Scan',
            color: const Color(0xFF2EC4B6),
            onTap: () => context.go('/scanner'),
          ),
          _ActionTile(
            icon: Icons.menu_book_rounded,
            label: 'Study',
            color: DesignTokens.primary,
            onTap: () => context.go('/materials'),
          ),
          _ActionTile(
            icon: Icons.quiz_rounded,
            label: 'Quiz',
            color: DesignTokens.secondary,
            onTap: () => context.go('/quizzes'),
          ),
          _ActionTile(
            icon: Icons.auto_awesome_rounded,
            label: 'AI',
            color: const Color(0xFF7C4DFF),
            onTap: () => context.go('/ai-tutor'),
          ),
          _ActionTile(
            icon: Icons.groups_rounded,
            label: 'Circles',
            color: const Color(0xFFE91E63),
            onTap: () => context.go('/circles'),
            badge: circlesCount > 0 ? circlesCount.toString() : null,
          ),
          _ActionTile(
            icon: Icons.article_rounded,
            label: 'Papers',
            color: const Color(0xFFF39C12),
            onTap: () => context.go('/paper-library'),
          ),
          _ActionTile(
            icon: Icons.upload_file_rounded,
            label: 'Upload',
            color: const Color(0xFF1F6A52),
            onTap: () => context.go('/upload-material'),
          ),
          _ActionTile(
            icon: Icons.emoji_events_rounded,
            label: 'Rank',
            color: const Color(0xFFFF6B35),
            onTap: () => context.go('/leaderboard'),
          ),
        ],
      );
    });
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPress(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: DesignTokens.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Continue Study Card ──────────────────────────────────────────────────────
class _ContinueStudyCard extends StatelessWidget {
  const _ContinueStudyCard({required this.progress});
  final StudyMaterialProgress progress;

  IconData get _icon {
    switch (progress.contentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd,
      ),
      child: AnimatedPress(
        onTap: () => context.push('/materials/${progress.slug}/read'),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B6CA8).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTINUE STUDYING',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.subjectName.isEmpty
                          ? progress.progressLabel
                          : '${progress.subjectName} · ${progress.progressLabel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              value: progress.completionRatio <= 0
                                  ? 0.05
                                  : progress.completionRatio,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFD700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(progress.completionRatio * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Focus Coach Card ─────────────────────────────────────────────────────────
class _FocusCoachCard extends StatelessWidget {
  const _FocusCoachCard({
    required this.weakestTopics,
    required this.strongestTopics,
    required this.strugglingTopics,
    required this.masteredTopics,
  });

  final List<String> weakestTopics;
  final List<String> strongestTopics;
  final List<String> strugglingTopics;
  final List<String> masteredTopics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusTopic =
        (weakestTopics.isNotEmpty ? weakestTopics : strugglingTopics)
            .firstOrNull;
    final confidenceTopic =
        (masteredTopics.isNotEmpty ? masteredTopics : strongestTopics)
            .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd,
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_alt_rounded,
                      color: Color(0xFF7C4DFF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Memory Coach',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        focusTopic != null
                            ? 'Revise your weakest areas faster.'
                            : 'Plan your next study session.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: DesignTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (focusTopic != null || confidenceTopic != null) ...[
              const SizedBox(height: 14),
              if (focusTopic != null)
                _TopicRow(
                  icon: Icons.flag_rounded,
                  color: DesignTokens.warning,
                  title: 'Focus next',
                  text: focusTopic,
                ),
              if (confidenceTopic != null) ...[
                const SizedBox(height: 8),
                _TopicRow(
                  icon: Icons.workspace_premium_rounded,
                  color: DesignTokens.success,
                  title: 'Strong in',
                  text: confidenceTopic,
                ),
              ],
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CoachChip(
                    icon: Icons.psychology_alt_outlined,
                    label: focusTopic == null
                        ? 'Open coach'
                        : 'Memorize $focusTopic',
                    onTap: () => context.go('/ai-tutor'),
                  ),
                  const SizedBox(width: 8),
                  _CoachChip(
                    icon: Icons.quiz_outlined,
                    label: focusTopic == null
                        ? 'Quiz me'
                        : 'Quiz on $focusTopic',
                    onTap: () => context.go('/ai-tutor'),
                  ),
                  const SizedBox(width: 8),
                  _CoachChip(
                    icon: Icons.event_note_outlined,
                    label: 'Plan tonight',
                    onTap: () => context.go('/ai-tutor'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _TopicRow(
      {required this.icon,
      required this.color,
      required this.title,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text('$title: ',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: DesignTokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _CoachChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CoachChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

// ── Adaptive Plan Card ───────────────────────────────────────────────────────
class _AdaptivePlanCard extends StatelessWidget {
  final String planSummary;
  final List<Map> tasks;
  final bool dark;
  const _AdaptivePlanCard(
      {required this.planSummary,
      required this.tasks,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: DesignTokens.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: DesignTokens.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Adaptive Study Plan',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (planSummary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(planSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary, height: 1.5)),
            ],
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tasks.take(3).map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: DesignTokens.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.chevron_right_rounded,
                                size: 14, color: DesignTokens.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${task['title'] ?? 'Task'}${task['reason'] != null ? ' — ${task['reason']}' : ''}',
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.go('/ai-tutor'),
              child: const Text('Open AI Tutor'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress Snapshot Card ───────────────────────────────────────────────────
class _ProgressSnapshotCard extends StatelessWidget {
  final dynamic snap;
  final List<String> strongestTopics;
  final List<String> weakestTopics;
  final bool dark;

  const _ProgressSnapshotCard({
    required this.snap,
    required this.strongestTopics,
    required this.weakestTopics,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Progress',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(
                  value: '${snap?['masteryPercent'] ?? 0}%',
                  label: 'Mastery',
                  color: DesignTokens.success,
                ),
                _StatPill(
                  value: '${snap?['avgQuizScore'] ?? 0}%',
                  label: 'Avg Score',
                  color: DesignTokens.primary,
                ),
                _StatPill(
                  value: '${snap?['questionsPracticed'] ?? 0}',
                  label: 'Questions',
                  color: DesignTokens.secondary,
                ),
                _StatPill(
                  value: '${snap?['attemptCount'] ?? 0}',
                  label: 'Attempts',
                  color: DesignTokens.info,
                ),
              ],
            ),
            if (strongestTopics.isNotEmpty || weakestTopics.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              if (strongestTopics.isNotEmpty)
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: DesignTokens.success),
                  const SizedBox(width: 6),
                  const Text('Strong: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Expanded(
                    child: Text(
                      strongestTopics.take(2).join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: DesignTokens.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              if (weakestTopics.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 15, color: DesignTokens.warning),
                  const SizedBox(width: 6),
                  const Text('Focus on: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Expanded(
                    child: Text(
                      weakestTopics.take(2).join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: DesignTokens.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              color: DesignTokens.textTertiary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Recent Material Card ─────────────────────────────────────────────────────
class _RecentMaterialCard extends StatelessWidget {
  final Map material;
  final bool dark;
  final VoidCallback onTap;
  const _RecentMaterialCard(
      {required this.material, required this.dark, required this.onTap});

  Color get _color {
    final subjectName = (material['subject']?['name'] ?? '').toLowerCase();
    if (subjectName.contains('math')) return DesignTokens.warning;
    if (subjectName.contains('science') || subjectName.contains('bio'))
      return DesignTokens.success;
    if (subjectName.contains('english') || subjectName.contains('chichewa'))
      return DesignTokens.primary;
    return DesignTokens.accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                  .withValues(alpha: 0.5)),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.description_rounded, color: _color, size: 18),
            ),
            const Spacer(),
            Text(
              material['title'] ?? '',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              material['subject']?['name'] ?? '',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: DesignTokens.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
