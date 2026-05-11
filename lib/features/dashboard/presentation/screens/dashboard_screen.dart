import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(document: gql(kDashboard)),
      builder: (result, {fetchMore, refetch}) {
        final me = result.data?['me'];
        final profile = me?['profile'];
        final recentMaterials = (result.data?['recentMaterials'] as List?) ?? [];
        final recentAttempts = (result.data?['recentQuizAttempts'] as List?) ?? [];
        final snap = result.data?['progressSnapshot'];
        final circles = (result.data?['myCircles'] as List?) ?? [];

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text('Yaza', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  actions: [
                    IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome card
                      _WelcomeCard(me: me, profile: profile),
                      const SizedBox(height: 20),

                      // Quick actions
                      Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _QuickActions(),
                      const SizedBox(height: 20),

                      // Progress snapshot
                      if (snap?['hasData'] == true) ...[
                        Text('Progress Snapshot', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _ProgressCard(snap: snap),
                        const SizedBox(height: 20),
                      ],

                      // Recent materials
                      if (recentMaterials.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Materials', style: Theme.of(context).textTheme.titleMedium),
                            TextButton(onPressed: () => context.go('/materials'), child: const Text('See all')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentMaterials.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _MaterialCard(material: recentMaterials[i]),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recent quiz attempts
                      if (recentAttempts.isNotEmpty) ...[
                        Text('Recent Quizzes', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...recentAttempts.map((a) => _QuizAttemptTile(attempt: a)),
                        const SizedBox(height: 20),
                      ],

                      // My circles
                      if (circles.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Circles', style: Theme.of(context).textTheme.titleMedium),
                            TextButton(onPressed: () => context.go('/circles'), child: const Text('See all')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...circles.map((c) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.groups)),
                          title: Text(c['name']),
                          subtitle: Text('${c['memberCount']} members'),
                          onTap: () => context.go('/circles/${c['slug']}'),
                          contentPadding: EdgeInsets.zero,
                        )),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final Map? me;
  final Map? profile;
  const _WelcomeCard({this.me, this.profile});

  @override
  Widget build(BuildContext context) {
    final streak = profile?['studyStreak'] ?? 0;
    final points = profile?['studyPoints'] ?? 0;
    final credits = profile?['aiCredits'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2980B9)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, ${me?['username'] ?? ''}! 👋',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(profile?['activePlanName'] ?? 'Free Plan',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(icon: '🔥', value: '$streak days', label: 'Streak'),
              const SizedBox(width: 8),
              _StatPill(icon: '⭐', value: '$points pts', label: 'Points'),
              const SizedBox(width: 8),
              _StatPill(icon: '💎', value: '$credits', label: 'Credits'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatPill({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text('$icon $value', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (icon: Icons.psychology, label: 'AI Tutor', color: AppColors.primary, route: '/ai-tutor'),
      (icon: Icons.document_scanner, label: 'Solve Paper', color: AppColors.secondary, route: '/scanner'),
      (icon: Icons.groups, label: 'Circles', color: AppColors.accent, route: '/circles'),
      (icon: Icons.leaderboard, label: 'Leaderboard', color: AppColors.success, route: '/leaderboard'),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () => context.go(a.route),
            child: Container(
              width: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: a.color.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: a.color, size: 28),
                  const SizedBox(height: 6),
                  Text(a.label, style: TextStyle(fontSize: 11, color: a.color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Map snap;
  const _ProgressCard({required this.snap});

  @override
  Widget build(BuildContext context) {
    final mastery = (snap['masteryPercent'] as num?)?.toDouble() ?? 0;
    final strongest = (snap['strongestTopics'] as List?)?.take(2).join(', ') ?? '';
    final weakest = (snap['weakestTopics'] as List?)?.take(2).join(', ') ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: mastery / 100, strokeWidth: 6, backgroundColor: Colors.grey.shade200),
                      Text('${mastery.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Mastery', style: Theme.of(context).textTheme.titleSmall),
                      Text('Avg score: ${(snap['avgQuizScore'] as num?)?.toStringAsFixed(0) ?? 0}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (strongest.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TopicRow(label: '💪 Strong', topics: strongest, color: AppColors.success),
            ],
            if (weakest.isNotEmpty) ...[
              const SizedBox(height: 6),
              _TopicRow(label: '📌 Focus', topics: weakest, color: AppColors.warning),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String label;
  final String topics;
  final Color color;
  const _TopicRow({required this.label, required this.topics, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(topics, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final Map material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/materials/${material['slug']}'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_contentTypeIcon(material['contentType']), color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(material['title'], maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(material['subject']?['name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _contentTypeIcon(String? type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'video': return Icons.play_circle_outline;
      case 'image': return Icons.image_outlined;
      default: return Icons.article_outlined;
    }
  }
}

class _QuizAttemptTile extends StatelessWidget {
  final Map attempt;
  const _QuizAttemptTile({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final color = score >= 70 ? AppColors.success : score >= 50 ? AppColors.warning : AppColors.error;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(attempt['quiz']?['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text('${score.toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      onTap: () => context.go('/quiz-results/${attempt['id']}'),
    );
  }
}
