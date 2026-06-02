import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../../core/graphql/queries/queries.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../quizzes/presentation/screens/quiz_card.dart';

class StudyQuizzesTab extends StatelessWidget {
  final bool dark;
  const StudyQuizzesTab({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Query(
      options:
          QueryOptions(document: gql(kQuizzes), variables: const {'limit': 50}),
      builder: (result, {fetchMore, refetch}) {
        final quizzes = (result.data?['quizzes'] as List?) ?? [];
        if (result.isLoading && quizzes.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(height: 96, radius: DesignTokens.radiusXl)),
          );
        }
        if (result.hasException && quizzes.isEmpty) {
          return ErrorState(
            message: graphQLErrorMessage(
                result.exception, 'Could not load quizzes.'),
            onRetry: () => refetch?.call(),
          );
        }
        if (quizzes.isEmpty) {
          return const EmptyState(
            icon: Icons.quiz_outlined,
            title: 'No quizzes yet',
            subtitle: 'Check back soon.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: quizzes.length,
            itemBuilder: (_, i) => QuizCard(
              quiz: quizzes[i] as Map<String, dynamic>,
              dark: dark,
              index: i,
            ),
          ),
        );
      },
    );
  }
}
