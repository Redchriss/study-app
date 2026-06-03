import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class QuizCommunityShareSheet extends ConsumerStatefulWidget {
  final String quizTitle;
  final String score;
  final WidgetRef ref;
  const QuizCommunityShareSheet(
      {required this.quizTitle, required this.score, required this.ref});

  @override
  ConsumerState<QuizCommunityShareSheet> createState() =>
      QuizCommunityShareSheetState();
}

class QuizCommunityShareSheetState
    extends ConsumerState<QuizCommunityShareSheet> {
  String? _slug;
  bool _posting = false;

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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Query(
              options: QueryOptions(document: gql(kMyCommunities)),
              builder: (qr, {fetchMore, refetch}) {
                final communities = (qr.data?['myCommunities'] as List?) ?? [];
                return DropdownButtonFormField<String>(
                  value: _slug,
                  decoration: const InputDecoration(
                      labelText: 'Select community',
                      border: OutlineInputBorder()),
                  items: communities
                      .map((c) => DropdownMenuItem(
                            value: c['slug']?.toString(),
                            child: Text('y/${c['name'] ?? c['slug']}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _slug = v),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_slug != null && !_posting) ? _post : null,
                icon: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_posting ? 'Posting...' : 'Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _post() async {
    if (_slug == null) return;
    setState(() => _posting = true);
    try {
      final client = widget.ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: {
          'communitySlug': _slug,
          'title': 'I scored ${widget.score}% on "${widget.quizTitle}" 🎉',
          'body':
              'Just completed the quiz on Yaza! Come challenge me 💪\n\nyaza.app',
          'postType': 'TEXT',
          'isOc': true,
          'isSpoiler': false,
        },
      ));
      if (!mounted) return;
      Navigator.pop(context);
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(graphQLErrorMessage(result.exception, 'Could not share')),
          backgroundColor: DesignTokens.error,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shared to community! 🎉'),
          backgroundColor: DesignTokens.success,
        ));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }
}
