import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 1)),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HeaderSkeleton()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
              child: Column(
                children: [
                  const SizedBox(height: DesignTokens.spMd),
                  const ShimmerBox(height: 90, radius: 16),
                  const SizedBox(height: DesignTokens.spMd),
                  const ShimmerBox(height: 80, radius: 16),
                  const SizedBox(height: DesignTokens.spMd),
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 80, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 80, radius: 16)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spMd),
                  const ShimmerBox(height: 160, radius: 16),
                  const SizedBox(height: DesignTokens.spMd),
                  SizedBox(
                    height: 140,
                    child: Row(
                      children: const [
                        ShimmerBox(width: 150, height: 140, radius: 16),
                        SizedBox(width: 10),
                        ShimmerBox(width: 150, height: 140, radius: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                            width: 100,
                            height: 14,
                            radius: 4,
                            baseColor:
                                Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 6),
                        ShimmerBox(
                            width: 160,
                            height: 26,
                            radius: 4,
                            baseColor:
                                Colors.white.withValues(alpha: 0.2)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ShimmerBox(
                        height: 50,
                        radius: 14,
                        baseColor:
                            Colors.white.withValues(alpha: 0.1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerBox(
                        height: 50,
                        radius: 14,
                        baseColor:
                            Colors.white.withValues(alpha: 0.1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerBox(
                        height: 50,
                        radius: 14,
                        baseColor:
                            Colors.white.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
