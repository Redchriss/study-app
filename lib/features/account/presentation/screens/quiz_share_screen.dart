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
  List? _circles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(graphqlClientProvider);
    final r = await client.query(QueryOptions(document: gql(kMyCommunities)));
    if (mounted) setState(() { _circles = (r.data?['myCommunities'] as List?) ?? []; _loading = false; });
  }

  Future<void> _shareToCircle(String circleSlug) async {
    final client = ref.read(graphqlClientProvider);
    final r = await client.mutate(MutationOptions(
      document: gql(kShareQuiz),
      variables: {'quizSlug': widget.quizSlug, 'circleSlug': circleSlug},
    ));
    if (mounted) {
      if (r.data?['shareQuiz']?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared to circle!')));
        context.pop();
      } else {
        final gqlErr = graphQLErrorMessage(r.exception, '');
        final message = gqlErr.isNotEmpty
            ? gqlErr
            : (r.data?['shareQuiz']?['errors'] as List?)?.firstOrNull?.toString() ?? 'Could not share quiz.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
      }
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
              const Text('Share to a circle:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 16),
              if (_circles!.isEmpty)
                const Text('You have not joined any circles.', style: TextStyle(color: DesignTokens.textTertiary)),
              ..._circles!.map((c) => Card(
                child: ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text('${c['memberCount'] ?? 0} members'),
                  trailing: const Icon(Icons.share),
                  onTap: () => _shareToCircle(c['slug']),
                ),
              )),
            ],
          ),
    );
  }
}
