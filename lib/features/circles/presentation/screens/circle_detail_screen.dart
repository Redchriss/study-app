import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const CircleDetailScreen({super.key, required this.slug});
  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  String _sort = 'hot';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _showNewPost = false;
  File? _postImage;
  String _postType = 'discussion';
  String _searchQuery = '';
  dynamic _refetch;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(kCircleDetail), variables: {'slug': widget.slug}, pollInterval: const Duration(seconds: 30)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final circle = result.data?['studyCircle'];
        if (circle == null) return const Scaffold(body: Center(child: Text('Circle not found')));
        return Scaffold(
          appBar: AppBar(
            title: Text(circle['name'] ?? ''),
            actions: [
              if (circle['isMember'] != true)
                Mutation(options: MutationOptions(document: gql(kJoinCircle)),
                  builder: (run, _) => IconButton(icon: const Icon(Icons.person_add), onPressed: () { run({'circleSlug': widget.slug}); refetch?.call(); }),
                ),
              IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
            ],
          ),
          body: Column(children: [
            if (circle['description'] != null && circle['description'] != '')
              Container(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                color: DesignTokens.primary.withValues(alpha: 0.04),
                child: Text(circle['description'], style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spXs),
              child: Row(children: [
                ChoiceChip(label: const Text('Hot'), selected: _sort == 'hot', onSelected: (_) => setState(() => _sort = 'hot')),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('New'), selected: _sort == 'new', onSelected: (_) => setState(() => _sort = 'new')),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('Top'), selected: _sort == 'top', onSelected: (_) => setState(() => _sort = 'top')),
                const Spacer(),
                AnimatedPress(
                  onTap: () => setState(() => _showNewPost = !_showNewPost),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 16, color: DesignTokens.primary), SizedBox(width: 4),
                      Text('Post', style: TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.primary)),
                    ]),
                  ),
                ),
              ]),
            ),
            if (_showNewPost)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
                child: Column(children: [
                  TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _bodyCtrl, decoration: const InputDecoration(labelText: 'Body', isDense: true), maxLines: 3),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (_postImage != null)
                      Stack(children: [
                        Image.file(_postImage!, height: 60, width: 60, fit: BoxFit.cover),
                        Positioned(right: 0, top: 0, child: GestureDetector(
                          onTap: () => setState(() => _postImage = null),
                          child: Container(
                            decoration: BoxDecoration(color: DesignTokens.error, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        )),
                      ])
                    else
                      GestureDetector(
                        onTap: () async {
                          final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
                          if (x != null) setState(() => _postImage = File(x.path));
                        },
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.image, color: DesignTokens.textSecondary),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _postType,
                      decoration: const InputDecoration(labelText: 'Type', isDense: true),
                      items: 'discussion|question|resource'.split('|').map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase()+t.substring(1)))).toList(),
                      onChanged: (v) => setState(() => _postType = v ?? 'discussion'),
                    )),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => _createPost(refetch), child: const Text('Post')),
                  ]),
                ]),
              ),
            Expanded(child: _buildPostsList(circle['slug'], refetch)),
          ]),
        );
      },
    );
  }

  Future<void> _createPost(dynamic refetch) async {
    if (_titleCtrl.text.trim().isEmpty || _posting) return;
    setState(() => _posting = true);
    String? b64;
    if (_postImage != null) {
      final bytes = await _postImage!.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image too large (max 3MB)'), backgroundColor: DesignTokens.error),
        );
        setState(() => _posting = false);
        return;
      }
      b64 = base64Encode(bytes);
    }
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kCreatePost),
      variables: {
        'circleSlug': widget.slug,
        'title': _titleCtrl.text,
        'content': _bodyCtrl.text,
        'postType': _postType,
        'imageBase64': b64,
      },
    ));
    if (mounted) {
      setState(() => _posting = false);
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${result.exception?.graphqlErrors.first.message ?? 'unknown error'}'), backgroundColor: DesignTokens.error),
        );
        return;
      }
      _titleCtrl.clear(); _bodyCtrl.clear();
      setState(() { _showNewPost = false; _postImage = null; });
      refetch?.call();
    }
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _PostSearchDelegate(widget.slug));
  }

  Widget _buildPostsList(String slug, dynamic refetch) {
    _refetch = refetch;
    return Query(
      options: QueryOptions(
        document: gql(kCirclePosts),
        variables: {'circleSlug': slug, 'sort': _sort},
        pollInterval: const Duration(seconds: 30),
      ),
      builder: (postResult, {fetchMore, refetch}) {
        if (postResult.isLoading) return const Center(child: CircularProgressIndicator());
        final posts = (postResult.data?['circlePosts'] as List?) ?? [];
        if (posts.isEmpty) return Center(child: Text('No posts yet', style: TextStyle(color: DesignTokens.textSecondary)));
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
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
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                      boxShadow: DesignTokens.shadowSm(Theme.of(context).brightness == Brightness.dark),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: Text(p['postType'] ?? '', style: TextStyle(fontSize: 10, color: DesignTokens.primary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(p['author']?['username'] ?? '', style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                      ]),
                      const SizedBox(height: 6),
                      Text(p['title'] ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      if (p['imageUrl'] != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          child: Image.network(p['imageUrl'], height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.arrow_upward, size: 14, color: DesignTokens.textTertiary),
                        Text('${p['score'] ?? 0}', style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                        const SizedBox(width: 12),
                        Icon(Icons.chat_bubble_outline, size: 14, color: DesignTokens.textTertiary),
                        Text('${p['commentCount'] ?? 0}', style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                      ]),
                    ]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostSearchDelegate extends SearchDelegate {
  final String circleSlug;
  _PostSearchDelegate(this.circleSlug);
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _buildSearch(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearch(context);

  Widget _buildSearch(BuildContext context) {
    if (query.isEmpty) return const EmptyState(icon: Icons.search, title: 'Search posts');
    return Query(
      options: QueryOptions(document: gql(kSearchPosts), variables: {'query': query, 'circleSlug': circleSlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        final posts = (result.data?['searchPosts'] as List?) ?? [];
        if (posts.isEmpty) return const EmptyState(icon: Icons.search_off, title: 'No results');
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final p = posts[i];
            return ListTile(
              title: Text(p['title'] ?? ''),
              subtitle: Text('${p['author']?['username'] ?? ''}  ·  ${p['commentCount'] ?? 0} comments'),
              onTap: () { close(context, null); context.go('/circles/$circleSlug/post/${p['slug']}'); },
            );
          },
        );
      },
    );
  }
}
