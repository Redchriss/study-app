import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/widgets/error_state.dart';
import 'report_card.dart';

class ModPanelReportsTab extends ConsumerWidget {
  final String communitySlug;

  const ModPanelReportsTab({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(kReportsQuery),
        variables: {'communitySlug': communitySlug, 'status': 'pending'},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (result.hasException) {
          return ErrorState(
            message: result.exception?.graphqlErrors.first.message ??
                'Failed to load reports',
            onRetry: () => refetch?.call(),
          );
        }
        final reports = result.data?['reports'] as List<dynamic>? ?? [];
        if (reports.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No pending reports',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Your community is looking good!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = reports[i] as Map<String, dynamic>;
              return ReportCard(
                report: r,
                communitySlug: communitySlug,
                onResolved: () => refetch?.call(),
              );
            },
          ),
        );
      },
    );
  }
}
