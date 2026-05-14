import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('History', style: theme.textTheme.titleLarge),
          bottom: TabBar(
            tabs: const [Tab(text: 'Transactions'), Tab(text: 'Credit Usage')],
            indicatorColor: DesignTokens.primary,
            labelColor: DesignTokens.primary,
          ),
        ),
        body: TabBarView(
          children: [
            Query(
              options: QueryOptions(document: gql(kPaymentHistory), variables: {'limit': 50}),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) return const Center(child: CircularProgressIndicator());
                if (result.hasException) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load transactions.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final items = (result.data?['paymentHistory'] as List?) ?? [];
                if (items.isEmpty) return const Center(child: Text('No transactions yet', style: TextStyle(color: DesignTokens.textTertiary)));
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final t = items[i];
                    final amount = (t['amount'] as num?)?.toStringAsFixed(0) ?? '0';
                    return ListTile(
                      title: Text(t['description'] ?? 'Payment', style: const TextStyle(fontSize: 14)),
                      subtitle: Text(t['createdAt'] ?? '', style: const TextStyle(fontSize: 11)),
                      trailing: Text('MK $amount', style: TextStyle(fontWeight: FontWeight.w700, color: t['status'] == 'completed' ? DesignTokens.success : DesignTokens.textSecondary)),
                    );
                  },
                );
              },
            ),
            Query(
              options: QueryOptions(document: gql(kCreditLedger), variables: {'limit': 50}),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) return const Center(child: CircularProgressIndicator());
                if (result.hasException) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load credit usage.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final items = (result.data?['creditLedger'] as List?) ?? [];
                if (items.isEmpty) return const Center(child: Text('No activity yet', style: TextStyle(color: DesignTokens.textTertiary)));
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: (e['delta'] ?? 0) > 0 ? DesignTokens.success.withValues(alpha: 0.1) : DesignTokens.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon((e['delta'] ?? 0) > 0 ? Icons.add : Icons.remove, color: (e['delta'] ?? 0) > 0 ? DesignTokens.success : DesignTokens.error, size: 20),
                      ),
                      title: Text(e['description'] ?? e['entryType'] ?? '', style: const TextStyle(fontSize: 14)),
                      subtitle: Text(e['createdAt'] ?? '', style: const TextStyle(fontSize: 11)),
                      trailing: Text('${e['delta'] ?? 0}', style: TextStyle(fontWeight: FontWeight.w700, color: (e['delta'] ?? 0) > 0 ? DesignTokens.success : DesignTokens.error)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
