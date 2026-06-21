import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../../core/graphql/queries/queries.dart';
import '../../../../../core/services/haptic_service.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../quizzes/presentation/screens/quiz_card.dart';

class StudyQuizzesTab extends StatefulWidget {
  final bool dark;
  const StudyQuizzesTab({super.key, required this.dark});

  @override
  State<StudyQuizzesTab> createState() => _StudyQuizzesTabState();
}

class _StudyQuizzesTabState extends State<StudyQuizzesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';
  String _difficulty = 'all';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _difficulties = [
    ('all', 'All', Icons.layers_rounded, DesignTokens.textTertiary),
    ('easy', 'Easy', Icons.sentiment_satisfied_rounded, DesignTokens.success),
    ('medium', 'Medium', Icons.sentiment_neutral_rounded, DesignTokens.warning),
    ('hard', 'Hard', Icons.sentiment_dissatisfied_rounded, DesignTokens.error),
  ];

  List<Map<String, dynamic>> _applyFilters(List rawQuizzes) {
    return rawQuizzes
        .whereType<Map>()
        .map((q) => Map<String, dynamic>.from(q))
        .where((q) {
      if (_difficulty != 'all') {
        final d = (q['difficulty'] ?? '').toString().toLowerCase();
        if (d != _difficulty) return false;
      }
      if (_search.isNotEmpty) {
        final s = _search.toLowerCase();
        return (q['title'] ?? '').toString().toLowerCase().contains(s) ||
            (q['subject']?['name'] ?? '').toString().toLowerCase().contains(s);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Query(
      options: QueryOptions(
          document: gql(kQuizzes),
          variables: const {'limit': 50},
          fetchPolicy: FetchPolicy.cacheAndNetwork),
      builder: (result, {fetchMore, refetch}) {
        final rawQuizzes = (result.data?['quizzes'] as List?) ?? [];
        final quizzes = _applyFilters(rawQuizzes);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Search quizzes...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => setState(
                                    () => _search = _ctrl.text = ''))
                            : null,
                        filled: true,
                        fillColor: widget.dark
                            ? DesignTokens.darkSurfaceVariant
                            : DesignTokens.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  if (rawQuizzes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.warning
                            .withValues(alpha: widget.dark ? 0.2 : 0.08),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Text(
                        '${quizzes.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: DesignTokens.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _difficulties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (val, label, icon, color) = _difficulties[i];
                  final isSelected = _difficulty == val;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() => _difficulty = val);
                      },
                      child: AnimatedContainer(
                        duration: DesignTokens.durFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                                  color, color.withValues(alpha: 0.7)])
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : color.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 14,
                                color: isSelected ? Colors.white : color),
                            const SizedBox(width: 5),
                            Text(label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected ? Colors.white : color,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: result.isLoading && rawQuizzes.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: ShimmerBox(
                              height: 96, radius: DesignTokens.radiusXl)),
                    )
                  : result.hasException && rawQuizzes.isEmpty
                      ? ErrorState(
                          message: graphQLErrorMessage(
                              result.exception, 'Could not load quizzes.'),
                          onRetry: () => refetch?.call(),
                        )
                      : quizzes.isEmpty
                          ? EmptyState(
                              icon: Icons.quiz_outlined,
                              title: _search.isNotEmpty ||
                                      _difficulty != 'all'
                                  ? 'No matches'
                                  : 'No quizzes yet',
                              subtitle: _search.isNotEmpty ||
                                      _difficulty != 'all'
                                  ? 'Try adjusting your filters.'
                                  : 'Check back soon.',
                            )
                          : RefreshIndicator(
                              onRefresh: () async => refetch?.call(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: quizzes.length,
                                itemBuilder: (_, i) => QuizCard(
                                  quiz: quizzes[i],
                                  dark: widget.dark,
                                  index: i,
                                ),
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}
