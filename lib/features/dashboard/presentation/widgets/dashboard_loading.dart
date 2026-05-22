import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Row(children: const [
                      Expanded(child: ShimmerBox(height: 90, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 90, radius: 16)),
                    ]),
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
