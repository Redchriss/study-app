import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class PastPaperLibraryScreen extends StatelessWidget {
  const PastPaperLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Past Papers', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(document: gql(kPastPapers)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(result.exception, 'Could not load past papers.'),
              onRetry: () => refetch?.call(),
            );
          }
          final papers = (result.data?['pastPapers'] as List?) ?? [];
          if (papers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No past papers available for your education level.\nPast papers are currently available for primary and secondary students.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DesignTokens.textTertiary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            itemCount: papers.length,
            itemBuilder: (_, i) {
              final p = papers[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p['subject'] ?? ''} · ${p['examType'] ?? ''} ${p['year'] ?? ''}', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/past-paper/view', extra: Map<String, dynamic>.from(p as Map));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
