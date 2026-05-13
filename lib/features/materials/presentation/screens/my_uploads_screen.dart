import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/graphql_options.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Lists materials uploaded by the current user (including pending review),
/// matching the web route `materials/uploads/mine/`.
class MyUploadsScreen extends ConsumerWidget {
  const MyUploadsScreen({super.key});

  static const int _pageSize = 40;

  Future<void> _deletePending(
    BuildContext context,
    WidgetRef ref,
    String slug,
    String title,
    VoidCallback refetch,
  ) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove upload?'),
        content: Text('Delete "$title"? This only works while the material is still pending review.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(
      GraphQLOptions.mutation(kDeleteMyMaterial, variables: {'slug': slug}),
    );
    if (!context.mounted) return;

    if (result.hasException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.exception?.graphqlErrors.first.message ?? 'Delete failed'),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    final payload = result.data?['deleteMyMaterial'];
    final ok = payload?['success'] == true;
    final errs = (payload?['errors'] as List?)?.cast<String>().join(' ') ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Upload removed.' : (errs.isNotEmpty ? errs : 'Could not delete.')),
        backgroundColor: ok ? DesignTokens.success : DesignTokens.error,
      ),
    );
    if (ok) refetch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('My uploads', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Query(
        options: GraphQLOptions.query(
          kMyUploadedMaterials,
          variables: {'limit': _pageSize, 'offset': 0},
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.hasException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: DesignTokens.error),
                    const SizedBox(height: DesignTokens.spSm),
                    Text(
                      result.exception?.graphqlErrors.first.message ?? 'Could not load uploads.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.spMd),
                    FilledButton(onPressed: () => refetch?.call(), child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final items = (result.data?['myUploadedMaterials'] as List?) ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 56, color: DesignTokens.textTertiary.withValues(alpha: 0.6)),
                    const SizedBox(height: DesignTokens.spMd),
                    Text(
                      'No uploads yet',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: DesignTokens.spXs),
                    Text(
                      'Submit study notes or resources for review. They appear here until approved.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                    ),
                    const SizedBox(height: DesignTokens.spLg),
                    FilledButton.icon(
                      onPressed: () => context.push('/upload-material'),
                      icon: const Icon(Icons.add),
                      label: const Text('Upload material'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = items[i] as Map<String, dynamic>;
                final slug = m['slug'] as String? ?? '';
                final title = m['title'] as String? ?? '';
                final subject = m['subject']?['name'] as String? ?? '';
                final type = (m['contentType'] as String? ?? '').toUpperCase();
                final approved = m['isApproved'] == true;
                return Card(
                  child: ListTile(
                    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [if (subject.isNotEmpty) subject, if (type.isNotEmpty) type].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            approved ? 'Live' : 'Pending',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: approved
                              ? DesignTokens.success.withValues(alpha: 0.15)
                              : DesignTokens.warning.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                        if (!approved)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: DesignTokens.error),
                            tooltip: 'Delete pending upload',
                            onPressed: slug.isEmpty ? null : () => _deletePending(context, ref, slug, title, () => refetch?.call()),
                          ),
                      ],
                    ),
                    onTap: slug.isEmpty ? null : () => context.push('/materials/$slug'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
