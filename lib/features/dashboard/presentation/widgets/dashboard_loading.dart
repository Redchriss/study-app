import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              ShimmerBox(height: 220, radius: 0),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ShimmerBox(height: 90, radius: 16),
                    SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: ShimmerBox(height: 90, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 90, radius: 16)),
                    ]),
                    SizedBox(height: 12),
                    ShimmerBox(height: 120, radius: 16),
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
