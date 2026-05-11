import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

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
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(r'''
        query CircleDetail($slug: String!) {
          studyCircle(slug: $slug) { id name description memberCount isMember isFavorite educationLevel }
        }
      '''), variables: {'slug': widget.slug}),
      builder: (result, {refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final circle = result.data?['studyCircle'];
        if (circle == null) return const Scaffold(body: Center(child: Text('Circle not found')));
        return Scaffold(
          appBar: AppBar(
            title: Text(circle['name'] ?? ''),
            actions: [
              if (circle['isMember'] != true)
                Mutation(
                  options: MutationOptions(document: gql(kJoinCircle)),
                  builder: (run, _) => IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      run({'circleSlug': widget.slug});
                      refetch?.call();
                    },
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (circle['description'] != null && circle['description'] != '')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Text(circle['description'], style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(label: const Text('New'), selected: _sort == 'new', onSelected: (_) => setState(() => _sort = 'new')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('Top'), selected: _sort == 'top', onSelected: (_) => setState(() => _sort = 'top')),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Post'),
                      onPressed: () => setState(() => _showNewPost = !_showNewPost),
                    ),
                  ],
                ),
              ),
              if (_showNewPost)
                Mutation(
                  options: MutationOptions(document: gql(kCreatePost)),
                  builder: (run, mut) => Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true), textInputAction: TextInputAction.next),
                        const SizedBox(height: 8),
                        TextField(controller: _bodyCtrl, decoration: const InputDecoration(labelText: 'Body', isDense: true), maxLines: 3),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: 'discussion',
                                decoration: const InputDecoration(labelText: 'Type', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'discussion', child: Text('Discussion')),
                                  DropdownMenuItem(value: 'question', child: Text('Question')),
                                  DropdownMenuItem(value: 'resource', child: Text('Resource')),
                                ],
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                run({'circleSlug': widget.slug, 'title': _titleCtrl.text, 'content': _bodyCtrl.text});
                                _titleCtrl.clear();
                                _bodyCtrl.clear();
                                setState(() => _showNewPost = false);
                                refetch?.call();
                              },
                              child: const Text('Post'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Query(
                  options: QueryOptions(
                    document: gql(kCirclePosts),
                    variables: {'circleSlug': widget.slug, 'sort': _sort},
                  ),
                  builder: (postResult, {refetch: refetchPosts}) {
                    if (postResult.isLoading) return const Center(child: CircularProgressIndicator());
                    final posts = (postResult.data?['circlePosts'] as List?) ?? [];
                    if (posts.isEmpty) return Center(child: Text('No posts yet', style: TextStyle(color: AppColors.textSecondary)));
                    return RefreshIndicator(
                      onRefresh: () async { refetch?.call(); refetchPosts?.call(); },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: posts.length,
                        itemBuilder: (_, i) {
                          final p = posts[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${p['author']['username'] ?? ''}  ·  ${p['upvoteCount'] ?? 0} 👍'),
                              trailing: p['commentCount'] > 0 ? Chip(label: Text('${p['commentCount']}', style: const TextStyle(fontSize: 11))) : null,
                              onTap: () => context.go('/circles/${widget.slug}/post/${p['slug']}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
