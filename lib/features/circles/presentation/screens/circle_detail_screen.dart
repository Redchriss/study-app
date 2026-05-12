import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const CircleDetailScreen({super.key, required this.slug});
  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  String _sort = 'new';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _showNewPost = false;

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(r'''
        query CD($slug: String!) {
          studyCircle(slug: $slug) { id name description memberCount isMember isFavorite educationLevel }
        }
      '''), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final circle = result.data?['studyCircle'];
        if (circle == null) return const Scaffold(body: Center(child: Text('Circle not found')));
        return Scaffold(
          appBar: AppBar(title: Text(circle['name'] ?? ''), centerTitle: true,
            actions: [if (circle['isMember'] != true)
              Mutation(options: MutationOptions(document: gql(kJoinCircle)),
                builder: (run, _) => IconButton(icon: const Icon(Icons.person_add), onPressed: () { run({'circleSlug': widget.slug}); refetch?.call(); }),
              ),
            ],
          ),
          body: Column(children: [
            if (circle['description'] != null && circle['description'] != '')
              Container(width: double.infinity, padding: const EdgeInsets.all(DesignTokens.spMd),
                color: DesignTokens.primary.withValues(alpha: 0.04),
                child: Text(circle['description'], style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spXs),
              child: Row(children: [
                ChoiceChip(label: const Text('New'), selected: _sort == 'new', onSelected: (_) => setState(() => _sort = 'new')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Top'), selected: _sort == 'top', onSelected: (_) => setState(() => _sort = 'top')),
                const Spacer(),
                AnimatedPress(
                  onTap: () => _showNewPost ? null : setState(() => _showNewPost = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 16, color: DesignTokens.primary),
                      SizedBox(width: 4),
                      Text('Post', style: TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.primary)),
                    ]),
                  ),
                ),
              ]),
            ),
            if (_showNewPost)
              Mutation(options: MutationOptions(document: gql(kCreatePost)),
                builder: (run, mut) => Container(
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
                  child: Column(children: [
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
                    const SizedBox(height: 8),
                    TextField(controller: _bodyCtrl, decoration: const InputDecoration(labelText: 'Body', isDense: true), maxLines: 3),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        initialValue: 'discussion', decoration: const InputDecoration(labelText: 'Type', isDense: true),
                        items: 'discussion|question|resource'.split('|').map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase()+t.substring(1)))).toList(),
                        onChanged: (_) {},
                      )),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () {
                        run({'circleSlug': widget.slug, 'title': _titleCtrl.text, 'content': _bodyCtrl.text});
                        _titleCtrl.clear(); _bodyCtrl.clear(); setState(() => _showNewPost = false); refetch?.call();
                      }, child: const Text('Post')),
                    ]),
                  ]),
                ),
              ),
            Expanded(child: Query(
              options: QueryOptions(document: gql(kCirclePosts), variables: {'circleSlug': widget.slug, 'sort': _sort}),
              builder: (postResult, {fetchMore, refetch}) {
                if (postResult.isLoading) return const Center(child: CircularProgressIndicator());
                final posts = (postResult.data?['circlePosts'] as List?) ?? [];
                if (posts.isEmpty) return Center(child: Text('No posts yet', style: TextStyle(color: DesignTokens.textSecondary)));
                return RefreshIndicator(
                  onRefresh: () async { refetch?.call(); },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
                    itemCount: posts.length,
                    itemBuilder: (_, i) {
                      final p = posts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
                        child: AnimatedPress(
                          onTap: () => context.go('/circles/${widget.slug}/post/${p['slug']}'),
                          child: Container(
                            padding: const EdgeInsets.all(DesignTokens.spMd),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                              border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                              boxShadow: DesignTokens.shadowSm(dark),
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['title'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${p['author']?['username'] ?? ''}  ·  ${p['upvoteCount'] ?? 0} 👍', style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12)),
                              ])),
                              if ((p['commentCount'] ?? 0) > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text('${p['commentCount']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
                                ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            )),
          ]),
        );
      },
    );
  }
}
