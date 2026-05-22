import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/parent_kid_summary_card.dart';

class ParentKidsProgressScreen extends StatelessWidget {
  const ParentKidsProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kParentKidOverview)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Scaffold(
            body: LoadingWidget(),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kids Progress')),
            body: ErrorState(
              message: graphQLErrorMessage(result.exception, 'Could not load child progress.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final summaries = ((result.data?['parentKidOverview'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kids Progress'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => refetch?.call(),
              ),
            ],
          ),
          body: summaries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No linked child profiles yet. Create a child in Kids mode first.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  itemCount: summaries.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parent Guide',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Celebrate effort, review together when a child has topics ready, and ask them to explain one idea back to you.',
                                style: TextStyle(color: DesignTokens.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ParentKidSummaryCard(summary: summaries[index - 1]);
                  },
                ),
        );
      },
    );
  }
}
