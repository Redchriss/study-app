import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

void showQuizShareSheet(
    BuildContext context, Map<String, dynamic>? attempt, WidgetRef ref) {
  final quizTitle = attempt?['quiz']?['title']?.toString() ?? 'Quiz';
  final score = attempt?['score']?.toStringAsFixed(0) ?? '0';
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share Quiz', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.groups),
                  label: const Text('Share to Community'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCommunityShareDialog(context, quizTitle, score, ref);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.public),
                  label: const Text('Make Public'),
                  onPressed: () async {
                    final client = ref.read(graphqlClientProvider);
                    await client.mutate(MutationOptions(
                      document: gql(kShareQuiz),
                      variables: {
                        'quizSlug': attempt?['quiz']?['slug'],
                        'makePublic': true
                      },
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ]),
      ),
    ),
  );
}

void _showCommunityShareDialog(
    BuildContext context, String quizTitle, String score, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => QuizCommunityShareSheet(
      quizTitle: quizTitle,
      score: score,
      ref: ref,
    ),
  );
}

class QuizCommunityShareSheet extends ConsumerStatefulWidget {
  final String quizTitle;
  final String score;
  final WidgetRef ref;
  const QuizCommunityShareSheet({
    super.key,
    required this.quizTitle,
    required this.score,
    required this.ref,
  });

  @override
  ConsumerState<QuizCommunityShareSheet> createState() =>
      _QuizCommunityShareSheetState();
}

class _QuizCommunityShareSheetState
    extends ConsumerState<QuizCommunityShareSheet> {
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
          'title': 'My ${widget.quizTitle} result',
          'body': 'I scored ${widget.score}% on ${widget.quizTitle}! \u{1F389}',
          'postType': 'TEXT',
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
                  initialValue: _selectedCommunity,
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
