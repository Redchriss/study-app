import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries_community.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModPanelSettingsTab extends ConsumerStatefulWidget {
  final String communitySlug;
  const ModPanelSettingsTab({super.key, required this.communitySlug});

  @override
  ConsumerState<ModPanelSettingsTab> createState() => _ModPanelSettingsTabState();
}

class _ModPanelSettingsTabState extends ConsumerState<ModPanelSettingsTab> {
  final _descriptionCtrl = TextEditingController();
  final _sidebarCtrl = TextEditingController();
  final _minAgeCtrl = TextEditingController();
  final _minKarmaCtrl = TextEditingController();
  String _communityType = 'public';
  bool _allowImages = true;
  bool _allowVideos = true;
  bool _allowPolls = true;
  bool _allowLinks = true;
  bool _allowGalleries = true;
  bool _allowCrossposts = true;
  bool _spoilersEnabled = false;
  bool _over18 = false;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _sidebarCtrl.dispose();
    _minAgeCtrl.dispose();
    _minKarmaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(r'''
          query CommunityForSettings($slug: String!) {
            community(slug: $slug) {
              id slug name displayName description sidebar
              communityType allowImages allowVideos allowPolls
              allowLinks allowGalleries allowCrossposts
              minAccountAgeDays minKarmaToPost spoilersEnabled over18
            }
          }
        '''),
        variables: {'slug': widget.communitySlug},
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        if (result.hasException) return ErrorState(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to load',
          onRetry: () => refetch?.call(),
        );
        final c = result.data?['community'] as Map<String, dynamic>?;
        if (c == null) return const Center(child: Text('Community not found'));
        _initFrom(c);
        return _buildForm();
      },
    );
  }

  void _initFrom(Map<String, dynamic> c) {
    _descriptionCtrl.text = c['description']?.toString() ?? '';
    _sidebarCtrl.text = c['sidebar']?.toString() ?? '';
    _communityType = c['communityType']?.toString() ?? 'public';
    _allowImages = c['allowImages'] == true;
    _allowVideos = c['allowVideos'] == true;
    _allowPolls = c['allowPolls'] == true;
    _allowLinks = c['allowLinks'] == true;
    _allowGalleries = c['allowGalleries'] == true;
    _allowCrossposts = c['allowCrossposts'] == true;
    _spoilersEnabled = c['spoilersEnabled'] == true;
    _over18 = c['over18'] == true;
    _minAgeCtrl.text = (c['minAccountAgeDays'] as num?)?.toString() ?? '0';
    _minKarmaCtrl.text = (c['minKarmaToPost'] as num?)?.toString() ?? '0';
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Community Type'),
        DropdownButtonFormField<String>(
          value: _communityType,
          items: const [
            DropdownMenuItem(value: 'public', child: Text('Public')),
            DropdownMenuItem(value: 'restricted', child: Text('Restricted')),
            DropdownMenuItem(value: 'private', child: Text('Private')),
          ],
          onChanged: (v) => setState(() => _communityType = v ?? 'public'),
        ),
        const SizedBox(height: 16),
        _section('Description'),
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Community description'),
        ),
        const SizedBox(height: 16),
        _section('Sidebar (Markdown)'),
        TextFormField(
          controller: _sidebarCtrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Sidebar content'),
        ),
        const SizedBox(height: 16),
        _section('Posting Controls'),
        Row(children: [
          Expanded(child: TextField(
            controller: _minAgeCtrl,
            decoration: const InputDecoration(labelText: 'Min account age (days)', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _minKarmaCtrl,
            decoration: const InputDecoration(labelText: 'Min karma to post', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 16),
        _section('Media & Content'),
        _switch('Allow images', _allowImages, (v) => setState(() => _allowImages = v)),
        _switch('Allow videos', _allowVideos, (v) => setState(() => _allowVideos = v)),
        _switch('Allow polls', _allowPolls, (v) => setState(() => _allowPolls = v)),
        _switch('Allow links', _allowLinks, (v) => setState(() => _allowLinks = v)),
        _switch('Allow galleries', _allowGalleries, (v) => setState(() => _allowGalleries = v)),
        _switch('Allow crossposts', _allowCrossposts, (v) => setState(() => _allowCrossposts = v)),
        _switch('Spoilers enabled', _spoilersEnabled, (v) => setState(() => _spoilersEnabled = v)),
        const SizedBox(height: 8),
        _section('Safety'),
        _switch('Over 18 community', _over18, (v) => setState(() => _over18 = v)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
          label: Text(_saving ? 'Saving...' : 'Save Settings'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateCommunity),
      variables: {
        'slug': widget.communitySlug,
        'description': _descriptionCtrl.text,
        'sidebar': _sidebarCtrl.text,
        'communityType': _communityType.toUpperCase(),
        'allowImages': _allowImages,
        'allowVideos': _allowVideos,
        'allowPolls': _allowPolls,
        'allowLinks': _allowLinks,
        'allowGalleries': _allowGalleries,
        'allowCrossposts': _allowCrossposts,
        'minAccountAgeDays': int.tryParse(_minAgeCtrl.text) ?? 0,
        'minKarmaToPost': int.tryParse(_minKarmaCtrl.text) ?? 0,
        'spoilersEnabled': _spoilersEnabled,
        'over18': _over18,
      },
    ));
    setState(() => _saving = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.hasException ? 'Failed to save' : 'Settings saved'),
      backgroundColor: result.hasException ? Theme.of(context).colorScheme.error : null,
    ));
  }
}
