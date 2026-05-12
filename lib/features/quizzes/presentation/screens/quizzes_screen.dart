import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes'), centerTitle: true),
      body: Query(
        options: QueryOptions(document: gql(kQuizzes), variables: {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final quizzes = (result.data?['quizzes'] as List?) ?? [];
          if (quizzes.isEmpty) return const Center(child: Text('No quizzes yet'));
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (_, i) {
                final q = quizzes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(q['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${q['subject']['name'] ?? ''}  ·  ${q['difficulty'] ?? ''}  ·  ${q['durationMinutes'] ?? '?'} min'),
                    trailing: Chip(label: Text('${q['questionCount'] ?? 0} Q', style: const TextStyle(fontSize: 11))),
                    onTap: () => context.go('/quiz/${q['slug']}'),
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
