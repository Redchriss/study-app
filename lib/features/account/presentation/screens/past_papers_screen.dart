import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PastPapersScreen extends ConsumerWidget {
  const PastPapersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text('My Solve History', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(
            document: gql(kMySolveSessions), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load solved papers.'),
              onRetry: () => refetch?.call(),
            );
          }
          final sessions = (result.data?['mySolveSessions'] as List?) ?? [];
          if (sessions.isEmpty)
            return const Center(
                child: Text('No solved papers yet. Use the scanner!',
                    style: TextStyle(color: DesignTokens.textTertiary)));
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              final filename = s['filename']?.toString() ?? '';
              final paperUrl = s['fileUrl']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: DesignTokens.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description,
                        color: DesignTokens.success, size: 22),
                  ),
                  title: Text(filename,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${s['subject'] ?? ''} · ${s['examType'] ?? ''} ${s['year'] ?? ''}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Share to Community button
                      IconButton(
                        icon: const Icon(Icons.share,
                            size: 18, color: DesignTokens.primary),
                        tooltip: 'Share to Community',
                        onPressed: () =>
                            _shareToCommunity(context, ref, filename, paperUrl),
                      ),
                      const SizedBox(width: 4),
                      Text(s['status'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: DesignTokens.primary)),
                    ],
                  ),
                  onTap: () {
                    context.push('/scanner/results',
                        extra: Map<String, dynamic>.from(s as Map));
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

void _shareToCommunity(
    BuildContext context, WidgetRef ref, String filename, String paperUrl) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => _CommunityShareSheet(
      title: 'Solved $filename — check my answers!',
      url: paperUrl,
      ref: ref,
    ),
  );
}

class _CommunityShareSheet extends ConsumerStatefulWidget {
  final String title;
  final String url;
  final WidgetRef ref;
  const _CommunityShareSheet({
    required this.title,
    required this.url,
    required this.ref,
  });

  @override
  ConsumerState<_CommunityShareSheet> createState() =>
      _CommunityShareSheetState();
}

class _CommunityShareSheetState extends ConsumerState<_CommunityShareSheet> {
  String? _selectedCommunity;
  bool _sharing = false;

  Future<void> _share() async {
    if (_selectedCommunity == null) return;
    setState(() => _sharing = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: {
          'communitySlug': _selectedCommunity,
          'title': widget.title,
          'body': 'Solved this past paper — check my answers!\n${widget.url}',
          'postType': 'LINK',
          'url': widget.url,
          'isOc': false,
          'isSpoiler': false,
        },
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(graphQLErrorMessage(result.exception, 'Could not share')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Shared to community!'),
            backgroundColor: DesignTokens.success),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share to Community',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Query(
              options: QueryOptions(document: gql(kMyCommunities)),
              builder: (qr, {fetchMore, refetch}) {
                final communities = (qr.data?['myCommunities'] as List?) ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedCommunity,
                  decoration: const InputDecoration(
                    labelText: 'Select community',
                    border: OutlineInputBorder(),
                  ),
                  items: communities
                      .map((c) => DropdownMenuItem(
                            value: c['slug']?.toString(),
                            child: Text('y/${c['name'] ?? c['slug']}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCommunity = v),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (_selectedCommunity != null && !_sharing) ? _share : null,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share),
                label: Text(_sharing ? 'Sharing...' : 'Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
