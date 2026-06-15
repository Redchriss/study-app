import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/constants/action_codes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text('Plans & Credits', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(document: gql(kCreditPackages)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load plans.'),
              onRetry: () => refetch?.call(),
            );
          }
          final pkgs = (result.data?['creditPackages'] as List?) ?? [];
          final credits = result.data?['me']?['profile']?['aiCredits'] ?? 0;
          final catalog = (result.data?['aiActionCatalog'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            children: [
              GlassCard(
                  child: Column(children: [
                const Icon(Icons.workspace_premium,
                    size: 40, color: DesignTokens.warning),
                const SizedBox(height: 8),
                Text('$credits',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.primary)),
                const Text('AI Credits remaining',
                    style: TextStyle(color: DesignTokens.textSecondary)),
              ])),
              const SizedBox(height: DesignTokens.spMd),
              if (catalog.isNotEmpty) ...[
                Text('Credit costs',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...catalog.map((a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(
                            child: Text(a['label'] ?? a['code'] ?? '',
                                style: const TextStyle(fontSize: 14))),
                        Text('−${a['cost'] ?? '?'} 💎',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.warning)),
                      ]),
                    )),
              ],
              const SizedBox(height: DesignTokens.spMd),
              Text('Top up credits',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...pkgs.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PackageTile(p, ref),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final Map<String, dynamic> p;
  final WidgetRef ref;
  const _PackageTile(this.p, this.ref);

  Future<void> _purchase(BuildContext context) async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kInitializePayment),
      variables: {
        'packageCode': p['code'],
        'purchaseType': p['purchaseType'] ?? ActionCodes.purchaseTypeTopup
      },
    ));
    if (!context.mounted) return;
    final data = result.data?['initializePayment'];
    if (data == null || data['success'] != true) {
      final gqlErr = graphQLErrorMessage(result.exception, '');
      final message = gqlErr.isNotEmpty
          ? gqlErr
          : (data?['errors'] as List?)?.join(', ') ?? 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
      );
      return;
    }
    final url = data['checkoutUrl'] as String?;
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Could not open payment page.'),
          backgroundColor: DesignTokens.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSub = p['purchaseType'] == ActionCodes.purchaseTypeSubscription;
    final amountStr = (p['amount'] as num?)?.toStringAsFixed(0) ?? '0';

    return AnimatedPress(
      onTap: () => _purchase(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSub
              ? const LinearGradient(
                  colors: [Color(0xFF6B48FF), Color(0xFF1B6CA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSub ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSub
              ? null
              : Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
          boxShadow: isSub
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B48FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSub
                    ? Colors.white.withValues(alpha: 0.2)
                    : DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSub
                    ? Icons.workspace_premium_rounded
                    : Icons.add_circle_outline_rounded,
                color: isSub ? Colors.white : DesignTokens.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p['name'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                isSub ? Colors.white : DesignTokens.textPrimary,
                          )),
                      if (p['badge'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DesignTokens.warning,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p['badge'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${p['credits']} credits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSub
                            ? Colors.white.withValues(alpha: 0.8)
                            : DesignTokens.textSecondary,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('MK $amountStr',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSub ? Colors.white : DesignTokens.primary,
                    )),
                if (isSub)
                  Text('/ month',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
