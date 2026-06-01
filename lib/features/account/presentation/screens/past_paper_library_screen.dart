import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class PastPaperLibraryScreen extends StatefulWidget {
  const PastPaperLibraryScreen({super.key});
  @override
  State<PastPaperLibraryScreen> createState() => _PastPaperLibraryScreenState();
}

class _PastPaperLibraryScreenState extends State<PastPaperLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      appBar: AppBar(
        backgroundColor: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        title: Text('Past Papers', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by subject, exam, year...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    })
                  : null,
              filled: true,
              fillColor: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: Query(
            options: QueryOptions(document: gql(kPastPapers)),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) return const LoadingWidget();
              if (result.hasException) {
                return ErrorState(message: graphQLErrorMessage(result.exception, 'Could not load past papers.'), onRetry: () => refetch?.call());
              }
              var papers = (result.data?['pastPapers'] as List?) ?? [];
              if (_query.isNotEmpty) {
                papers = papers.where((p) {
                  final title = (p['title'] ?? '').toString().toLowerCase();
                  final subject = (p['subject'] ?? '').toString().toLowerCase();
                  final exam = (p['examType'] ?? '').toString().toLowerCase();
                  final year = (p['year'] ?? '').toString();
                  return title.contains(_query) || subject.contains(_query) || exam.contains(_query) || year.contains(_query);
                }).toList();
              }
              if (papers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _query.isNotEmpty ? 'No papers match "$_query"' : 'No past papers available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textTertiary),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: papers.length,
                itemBuilder: (_, i) {
                  final p = papers[i];
                  final subject = (p['subject'] ?? '').toString();
                  final exam = (p['examType'] ?? '').toString();
                  final year = (p['year'] ?? '').toString();
                  final subtitle = [if (subject.isNotEmpty) subject, if (exam.isNotEmpty) exam, if (year.isNotEmpty) year].join(' · ');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: DesignTokens.primary, size: 22),
                      ),
                      title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
                      onTap: () => context.push('/past-paper/view', extra: Map<String, dynamic>.from(p as Map)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
