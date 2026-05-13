import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Plans & Credits', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(document: gql(kCreditPackages)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final pkgs = (result.data?['creditPackages'] as List?) ?? [];
          final credits = result.data?['me']?['profile']?['aiCredits'] ?? 0;
          final catalog = (result.data?['aiActionCatalog'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            children: [
              GlassCard(child: Column(children: [
                const Icon(Icons.auto_awesome, size: 40, color: DesignTokens.warning),
                const SizedBox(height: 8),
                Text('$credits', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: DesignTokens.primary)),
                const Text('AI Credits remaining', style: TextStyle(color: DesignTokens.textSecondary)),
              ])),
              const SizedBox(height: DesignTokens.spMd),
              if (catalog.isNotEmpty) ...[
                Text('Credit costs', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...catalog.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(a['label'] ?? a['code'] ?? '', style: const TextStyle(fontSize: 14))),
                    Text('−${a['cost'] ?? '?'} 💎', style: const TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.warning)),
                  ]),
                )),
              ],
              const SizedBox(height: DesignTokens.spMd),
              Text('Top up credits', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...pkgs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(child: _PackageTile(p, ref)),
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
      variables: {'packageCode': p['code'], 'purchaseType': p['purchaseType'] ?? 'topup'},
    ));
    if (!context.mounted) return;
    final data = result.data?['initializePayment'];
    if (data == null || data['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data?['errors']?.join(', ') ?? 'Payment failed'), backgroundColor: DesignTokens.error),
      );
      return;
    }
    final url = data['checkoutUrl'] as String?;
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(p['purchaseType'] == 'subscription' ? Icons.auto_awesome : Icons.add_circle, color: DesignTokens.primary),
      ),
      title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${p['credits']} credits', style: const TextStyle(fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('MK ${p['amount']?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary)),
        if (p['badge'] != null) Text(p['badge'], style: const TextStyle(fontSize: 10, color: DesignTokens.warning)),
      ]),
      onTap: () => _purchase(context),
    );
  }
}
