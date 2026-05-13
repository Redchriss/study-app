import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class PastPapersScreen extends StatelessWidget {
  const PastPapersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('My Solve History', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(document: gql(kMySolveSessions), variables: {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final sessions = (result.data?['mySolveSessions'] as List?) ?? [];
          if (sessions.isEmpty) return const Center(child: Text('No solved papers yet. Use the scanner!', style: TextStyle(color: DesignTokens.textTertiary)));
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description, color: DesignTokens.success, size: 22),
                  ),
                  title: Text(s['filename'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${s['subject'] ?? ''} · ${s['examType'] ?? ''} ${s['year'] ?? ''}', style: const TextStyle(fontSize: 12)),
                  trailing: Text(s['status'] ?? '', style: const TextStyle(fontSize: 12, color: DesignTokens.primary)),
                  onTap: () {
                    context.push('/scanner/results', extra: s);
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
