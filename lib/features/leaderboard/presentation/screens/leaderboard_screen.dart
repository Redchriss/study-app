import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'leaderboard_tab.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leaderboard',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [Tab(text: 'Top Learners'), Tab(text: 'Top Contributors')],
            indicatorColor: DesignTokens.primary,
            labelColor: DesignTokens.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(category: 'learners'),
            LeaderboardTab(category: 'contributors')
          ],
        ),
      ),
    );
  }
}
