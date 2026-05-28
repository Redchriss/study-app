import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Detail for a curated past paper from [kPastPapers] (matches web paper list / detail intent).
class PastPaperDetailScreen extends ConsumerWidget {
  const PastPaperDetailScreen({super.key, required this.paper});

  final Map<String, dynamic> paper;

  Future<void> _openFile(BuildContext context) async {
    final raw = paper['fileUrl'] as String?;
    if (raw == null || raw.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No PDF file is linked for this paper yet.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file link.')),
        );
      }
      return;
    }
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot open this link on this device.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = paper['title']?.toString() ?? 'Past paper';
    final subject = paper['subject']?.toString() ?? '';
    final exam = paper['examType']?.toString() ?? '';
    final year = paper['year']?.toString() ?? '';
    final level = paper['educationLevel']?.toString() ?? '';
    final hasFile = (paper['fileUrl'] as String?)?.isNotEmpty == true;
    final fileUrl = paper['fileUrl']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Share to Community button
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share to Community',
            onPressed: () => _showShareSheet(context, ref, title, fileUrl),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DesignTokens.spSm),
                  if (subject.isNotEmpty) _kv(context, 'Subject', subject),
                  if (exam.isNotEmpty) _kv(context, 'Exam', exam),
                  if (year.isNotEmpty) _kv(context, 'Year', year),
                  if (level.isNotEmpty) _kv(context, 'Level', level),
                  if (subject.isEmpty &&
                      exam.isEmpty &&
                      year.isEmpty &&
                      level.isEmpty)
                    Text('No extra metadata.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: DesignTokens.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasFile ? () => _openFile(context) : null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(hasFile ? 'Open PDF' : 'PDF not available'),
            ),
          ),
          const SizedBox(height: DesignTokens.spSm),
          Text(
            'Opens in your browser or PDF app. You can also practice questions from similar papers in Quizzes.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: DesignTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(
      BuildContext context, WidgetRef ref, String title, String fileUrl) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PastPaperShareSheet(
        title: 'Check out this past paper: $title',
        url: fileUrl,
        ref: ref,
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(k,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: DesignTokens.textSecondary)),
          ),
          Expanded(
              child:
                  Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _PastPaperShareSheet extends ConsumerStatefulWidget {
  final String title;
  final String url;
  final WidgetRef ref;
  const _PastPaperShareSheet({
    required this.title,
    required this.url,
    required this.ref,
  });

  @override
  ConsumerState<_PastPaperShareSheet> createState() =>
      _PastPaperShareSheetState();
}

class _PastPaperShareSheetState extends ConsumerState<_PastPaperShareSheet> {
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
