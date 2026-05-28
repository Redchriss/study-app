import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Search posts...', border: InputBorder.none),
          onSubmitted: (q) => setState(() => _query = q.trim()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => _query = _ctrl.text.trim()),
          ),
        ],
      ),
      body: _query.isEmpty
          ? const Center(
              child: Text('Type a query to search',
                  style: TextStyle(color: DesignTokens.textSecondary)))
          : Query(
              key: ValueKey('search_$_query'),
              options: QueryOptions(
                document: gql(kSearchPosts),
                variables: {'query': _query, 'limit': 25},
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(children: [
                      ShimmerBox(height: 100, radius: 12),
                      SizedBox(height: 8),
                      ShimmerBox(height: 100, radius: 12),
                    ]),
                  );
                }
                if (result.hasException) {
                  return ErrorState(
                    message: 'Search failed',
                    onRetry: () => refetch?.call(),
                  );
                }
                final data = result.data?['searchPosts'];
                final edges = (data?['edges'] as List?) ?? [];
                final posts = edges
                    .map((e) => e['node'] as Map<String, dynamic>)
                    .toList();

                if (posts.isEmpty) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No results for "$_query"',
                        style:
                            const TextStyle(color: DesignTokens.textSecondary)),
                  ));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(
                    post: posts[i],
                    layout: PostCardLayout.compact,
                    onTap: () {
                      final c = posts[i]['community'];
                      if (c != null) {
                        context
                            .push('/y/${c['slug']}/post/${posts[i]['slug']}');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
