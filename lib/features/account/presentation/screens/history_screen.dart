import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('History', style: theme.textTheme.titleLarge),
          bottom: const TabBar(
            tabs: [Tab(text: 'Transactions'), Tab(text: 'Credit Usage')],
            indicatorColor: DesignTokens.primary,
            labelColor: DesignTokens.primary,
          ),
        ),
        body: TabBarView(
          children: [
            Query(
              options: QueryOptions(document: gql(kPaymentHistory), variables: const {'limit': 50}),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) return const LoadingWidget();
                if (result.hasException) {
                  return ErrorState(
                    message: graphQLErrorMessage(result.exception, 'Could not load transactions.'),
                    onRetry: () => refetch?.call(),
                  );
                }
                final items = (result.data?['paymentHistory'] as List?) ?? [];
                if (items.isEmpty) return const Center(child: Text('No transactions yet', style: TextStyle(color: DesignTokens.textTertiary)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final t = items[i];
                    final amount = (t['amount'] as num?)?.toStringAsFixed(0) ?? '0';
                    final isCompleted = t['status'] == 'completed';
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: dark ? DesignTokens.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? DesignTokens.success.withValues(alpha: 0.1) 
                                  : DesignTokens.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: isCompleted ? DesignTokens.success : DesignTokens.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['packageName'] ?? 'Payment', 
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t['createdAt'] ?? '', 
                                  style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MK $amount', 
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800, 
                              color: isCompleted ? DesignTokens.success : DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            Query(
              options: QueryOptions(document: gql(kCreditLedger), variables: const {'limit': 50}),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) return const LoadingWidget();
                if (result.hasException) {
                  return ErrorState(
                    message: graphQLErrorMessage(result.exception, 'Could not load credit usage.'),
                    onRetry: () => refetch?.call(),
                  );
                }
                final items = (result.data?['creditLedger'] as List?) ?? [];
                if (items.isEmpty) return const Center(child: Text('No activity yet', style: TextStyle(color: DesignTokens.textTertiary)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final delta = (e['delta'] as num?)?.toInt() ?? 0;
                    final isPositive = delta > 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: dark ? DesignTokens.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isPositive 
                                  ? DesignTokens.success.withValues(alpha: 0.1) 
                                  : const Color(0xFFE87E5E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPositive ? Icons.add_rounded : Icons.auto_awesome_rounded, 
                              color: isPositive ? DesignTokens.success : const Color(0xFFE87E5E), 
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['description'] ?? e['entryType'] ?? '', 
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e['createdAt'] ?? '', 
                                  style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isPositive ? '+' : ''}$delta', 
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900, 
                              color: isPositive ? DesignTokens.success : const Color(0xFFE87E5E),
                            ),
                          ),
                        ],
                      ),
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
