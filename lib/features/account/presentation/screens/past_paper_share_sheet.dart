import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PastPaperShareSheet extends ConsumerStatefulWidget {
  final String title;
  final String url;
  const PastPaperShareSheet({super.key, required this.title, required this.url});
  @override
  ConsumerState<PastPaperShareSheet> createState() => _PastPaperShareSheetState();
}

class _PastPaperShareSheetState extends ConsumerState<PastPaperShareSheet> {
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
          'body': 'Past paper: ${widget.url}',
          'postType': 'LINK',
          'url': widget.url.isNotEmpty ? widget.url : null,
          'isOc': false,
          'isSpoiler': false,
        },
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(graphQLErrorMessage(result.exception, 'Could not share')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared to community!'), backgroundColor: DesignTokens.success),
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
            Text('Share to Community', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Query(
              options: QueryOptions(document: gql(kMyCommunities)),
              builder: (qr, {fetchMore, refetch}) {
                final communities = (qr.data?['myCommunities'] as List?) ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedCommunity,
                  decoration: const InputDecoration(labelText: 'Select community', border: OutlineInputBorder()),
                  items: communities.map((c) => DropdownMenuItem(value: c['slug']?.toString(), child: Text('y/${c['name'] ?? c['slug']}'))).toList(),
                  onChanged: (v) => setState(() => _selectedCommunity = v),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_selectedCommunity != null && !_sharing) ? _share : null,
                icon: _sharing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
