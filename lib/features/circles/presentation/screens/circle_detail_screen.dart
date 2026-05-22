import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'circle_detail_search.dart';
import 'circle_detail_widgets.dart';
import 'circle_new_post_form.dart';
import 'circle_posts_list.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const CircleDetailScreen({super.key, required this.slug});
  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  String _sort = 'hot';
  String _typeFilter = 'all';
  bool _solvedOnly = false;
  bool _showNewPost = false;

  void _showSearch() {
    showSearch(
        context: context, delegate: CirclePostSearchDelegate(widget.slug));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(
          document: gql(kCircleDetail),
          variables: {'slug': widget.slug},
          pollInterval: const Duration(seconds: 30)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Scaffold(
              body: LoadingWidget());
        }
        if (result.hasException) {
          return Scaffold(
            body: ErrorState(
              message: graphQLErrorMessage(result.exception, 'Failed to load circle'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final circle = result.data?['studyCircle'] as Map<String, dynamic>?;
        if (circle == null) {
          return const Scaffold(body: Center(child: Text('Circle not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(circle['name']?.toString() ?? ''),
            actions: [
              if (circle['isMember'] != true)
                Mutation(
                  options: MutationOptions(document: gql(kJoinCircle)),
                  builder: (run, _) => IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () {
                        run({'slug': widget.slug});
                        refetch?.call();
                      }),
                ),
              IconButton(
                  icon: const Icon(Icons.search), onPressed: _showSearch),
              if (circle['isMember'] == true)
                Mutation(
                  options:
                      MutationOptions(document: gql(kToggleFavouriteCircle)),
                  builder: (run, _) => IconButton(
                    icon: Icon(
                        circle['isFavorite'] == true
                            ? Icons.star
                            : Icons.star_border,
                        color: circle['isFavorite'] == true
                            ? DesignTokens.warning
                            : null),
                    onPressed: () {
                      run({'circleSlug': widget.slug});
                      refetch?.call();
                    },
                  ),
                ),
            ],
          ),
          body: Column(children: [
            if (circle['description']?.toString().isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                color: DesignTokens.primary.withValues(alpha: 0.04),
                child: Text(circle['description']!.toString(),
                    style: const TextStyle(
                        color: DesignTokens.textSecondary, fontSize: 13)),
              ),
            CircleHeroBanner(circle: circle, dark: dark),
            CircleFilterBar(
              sort: _sort,
              typeFilter: _typeFilter,
              solvedOnly: _solvedOnly,
              onSortChanged: (v) => setState(() => _sort = v),
              onTypeFilterChanged: (v) => setState(() => _typeFilter = v),
              onSolvedOnlyChanged: (v) => setState(() => _solvedOnly = v),
              showNewPost: _showNewPost,
              onToggleNewPost: () =>
                  setState(() => _showNewPost = !_showNewPost),
            ),
            if (_showNewPost)
              CircleNewPostForm(
                circleSlug: widget.slug,
                onClose: () => setState(() => _showNewPost = false),
                onPosted: () {
                  setState(() => _showNewPost = false);
                  refetch?.call();
                },
              ),
            Expanded(
                child: CirclePostsList(
              slug: widget.slug,
              sort: _sort,
              typeFilter: _typeFilter,
              solvedOnly: _solvedOnly,
              onRefetch: () => refetch?.call(),
            )),
          ]),
        );
      },
    );
  }
}
