import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? communitySlug;
  const CreatePostScreen({super.key, this.communitySlug});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _communitySlug;
  String _postType = 'text';
  bool _isOc = false;
  bool _isSpoiler = false;
  bool _submitting = false;

  final _postTypes = [
    {'key': 'text', 'icon': '📝', 'label': 'Text'},
    {'key': 'link', 'icon': '🔗', 'label': 'Link'},
    {'key': 'image', 'icon': '🖼', 'label': 'Image'},
    {'key': 'poll', 'icon': '📊', 'label': 'Poll'},
  ];

  @override
  void initState() {
    super.initState();
    _communitySlug = widget.communitySlug;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_communitySlug == null || _communitySlug!.isEmpty) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_postType == 'link' && _urlCtrl.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final vars = {
        'communitySlug': _communitySlug,
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'postType': _postType,
        'url': _postType == 'link' ? _urlCtrl.text.trim() : null,
        'isOc': _isOc,
        'isSpoiler': _isSpoiler,
      };
      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: vars,
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(graphQLErrorMessage(result.exception, 'Could not create post')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      final payload = result.data?['createPost'];
      final errors = (payload?['errors'] as List?)?.join(', ');
      if (errors != null && errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errors), backgroundColor: DesignTokens.error,
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Post created!'), backgroundColor: DesignTokens.success,
      ));
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Post', style: TextStyle(fontWeight: FontWeight.w700, color: _isValid ? DesignTokens.primary : DesignTokens.textTertiary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommunityPicker(
              selected: _communitySlug,
              onChanged: (v) => setState(() => _communitySlug = v),
            ),
            const SizedBox(height: 16),
            Text('Post Type',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: _postTypes.map((t) {
                final selected = _postType == t['key'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${t['icon']} ${t['label']}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      selected: selected,
                      onSelected: (_) => setState(() => _postType = t['key'] as String),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder(),
              ),
              maxLength: 300,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_postType == 'link')
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL', border: OutlineInputBorder(), hintText: 'https://...',
                ),
                onChanged: (_) => setState(() {}),
              ),
            if (_postType == 'text')
              TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body (markdown)', border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8, minLines: 4,
              ),
            if (_postType != 'link') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('OC', style: TextStyle(fontSize: 12)),
                    selected: _isOc,
                    onSelected: (v) => setState(() => _isOc = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Spoiler', style: TextStyle(fontSize: 12)),
                    selected: _isSpoiler,
                    onSelected: (v) => setState(() => _isSpoiler = v),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CommunityPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kMyCommunities)),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        return DropdownButtonFormField<String>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Community', border: OutlineInputBorder(),
          ),
          hint: const Text('Select community'),
          items: communities.map((c) {
            return DropdownMenuItem(
              value: c['slug']?.toString(),
              child: Text('y/${c['name'] ?? c['slug']}'),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
