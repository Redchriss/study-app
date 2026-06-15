import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'dashboard_hero_tiles.dart';

class DashboardHeroHeader extends StatefulWidget {
  final String name;
  final String educationLevel;
  final int streak;
  final int points;
  final int credits;
  final int dailyProgress;
  final int dailyGoal;
  final bool dark;
  final VoidCallback onNotification;
  final VoidCallback onAiTutor;
  final bool showDailyGoal;

  const DashboardHeroHeader({
    super.key,
    required this.name,
    required this.educationLevel,
    required this.streak,
    required this.points,
    required this.credits,
    required this.dark,
    required this.onNotification,
    required this.onAiTutor,
    this.dailyProgress = 0,
    this.dailyGoal = 10,
    this.showDailyGoal = false,
  });

  @override
  State<DashboardHeroHeader> createState() => _DashboardHeroHeaderState();
}

class _DashboardHeroHeaderState extends State<DashboardHeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: 6.seconds,
    )..repeat();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _levelLabel {
    switch (widget.educationLevel.toLowerCase()) {
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
    final dailyPct = widget.dailyGoal > 0
        ? (widget.dailyProgress / widget.dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF1B6CA8),
                  const Color(0xFF155885),
                  _gradientCtrl.value,
                )!,
                Color.lerp(
                  const Color(0xFF155885),
                  const Color(0xFF0D2E4A),
                  _gradientCtrl.value,
                )!,
                Color.lerp(
                  const Color(0xFF0D2E4A),
                  const Color(0xFF0A1E33),
                  _gradientCtrl.value,
                )!,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopRow(),
                const SizedBox(height: 16),
                _buildStatsRow(dailyPct),
                if (widget.showDailyGoal && widget.streak > 0) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: StreakDotsRow(
                      streak: widget.streak,
                      dailyProgress: widget.dailyProgress,
                      dailyGoal: widget.dailyGoal,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildAiTutorButton(),
                const SizedBox(height: 16),
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.dark
                        ? DesignTokens.darkBackground
                        : DesignTokens.background,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting,',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(widget.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(_levelLabel,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                onPressed: widget.onNotification),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double dailyPct) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: HeroStatTile(
              value: widget.streak.toString(),
              label: 'Day Streak',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF9800),
              iconBg: const Color(0x33FF9800),
              subtitle: widget.streak > 0
                  ? '${widget.streak} day${widget.streak == 1 ? '' : 's'}'
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          if (widget.showDailyGoal)
            Expanded(
              child: DailyGoalRingTile(
                progress: dailyPct,
                value: '${widget.dailyProgress}',
                label: 'Daily Goal',
              ),
            )
          else
            Expanded(
              child: HeroStatTile(
                value: widget.points.toString(),
                label: 'Points',
                icon: Icons.star_rounded,
                color: const Color(0xFFFFD700),
                iconBg: const Color(0x33FFD700),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: HeroStatTile(
              value: widget.credits.toString(),
              label: 'Credits',
              icon: Icons.bolt_rounded,
              color: const Color(0xFF69F0AE),
              iconBg: const Color(0x3369F0AE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTutorButton() {
    return GestureDetector(
      onTap: widget.onAiTutor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Study with AI Tutor',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
