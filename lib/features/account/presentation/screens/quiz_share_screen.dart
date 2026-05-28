import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class QuizShareScreen extends ConsumerStatefulWidget {
  final String quizSlug;
  const QuizShareScreen({super.key, required this.quizSlug});
  @override
  ConsumerState<QuizShareScreen> createState() => _QuizShareScreenState();
}

class _QuizShareScreenState extends ConsumerState<QuizShareScreen> {
  List? _communities;
  bool _loading = true;
  bool _sharing = false;
  String? _selectedCommunity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(graphqlClientProvider);
    final r = await client.query(QueryOptions(document: gql(kMyCommunities)));
    if (mounted) {
      setState(() {
        _communities = (r.data?['myCommunities'] as List?) ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _shareToCommunity() async {
    if (_selectedCommunity == null) return;
    setState(() => _sharing = true);
    try {
      final client = ref.read(graphqlClientProvider);
      // Fetch quiz details for the share post
      final quizResult = await client.query(QueryOptions(
        document: gql(kQuiz),
        variables: {'slug': widget.quizSlug},
      ));
      final quizTitle =
          quizResult.data?['quiz']?['title']?.toString() ?? 'Quiz';

      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: {
          'communitySlug': _selectedCommunity,
          'title': 'Check out this quiz: $quizTitle',
          'body':
              'I found this quiz on Yaza! Check it out: https://yaza.app/quiz/${widget.quizSlug}',
          'postType': 'LINK',
          'url': 'https://yaza.app/quiz/${widget.quizSlug}',
          'isOc': false,
          'isSpoiler': false,
        },
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              graphQLErrorMessage(result.exception, 'Could not share quiz')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Quiz shared to community!'),
            backgroundColor: DesignTokens.success),
      );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Quiz')),
      body: _loading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Share to a community:',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 16),
                if (_communities!.isEmpty)
                  const Text('You have not joined any communities.',
                      style: TextStyle(color: DesignTokens.textTertiary)),
                ..._communities!.map((c) => Card(
                      child: ListTile(
                        title: Text(c['name'] ?? ''),
                        subtitle: Text('${c['memberCount'] ?? 0} members'),
                        trailing: _selectedCommunity == c['slug']
                            ? const Icon(Icons.check_circle,
                                color: DesignTokens.primary)
                            : const Icon(Icons.share),
                        onTap: () {
                          setState(() => _selectedCommunity = c['slug']);
                        },
                      ),
                    )),
                if (_selectedCommunity != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _sharing ? null : _shareToCommunity,
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.share),
                      label: Text(_sharing
                          ? 'Sharing...'
                          : 'Share to y/$_selectedCommunity'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
