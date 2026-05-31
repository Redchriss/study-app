import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'mod_panel_member_widgets.dart';

class ModPanelMembersTab extends ConsumerStatefulWidget {
  final String communitySlug;
  const ModPanelMembersTab({super.key, required this.communitySlug});

  @override
  ConsumerState<ModPanelMembersTab> createState() => _ModPanelMembersTabState();
}

class _ModPanelMembersTabState extends ConsumerState<ModPanelMembersTab>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late TabController _memberTabCtrl;

  @override
  void initState() {
    super.initState();
    _memberTabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _memberTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(graphqlClientProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search username...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (q) => setState(() => _searchQuery = q.trim()),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _memberTabCtrl,
          tabs: const [Tab(text: 'Moderators'), Tab(text: 'Banned'), Tab(text: 'Muted')],
          labelColor: DesignTokens.primary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
        ),
        Expanded(
          child: _searchQuery.isNotEmpty
              ? SearchedUserActions(communitySlug: widget.communitySlug, username: _searchQuery, client: client)
              : TabBarView(
                  controller: _memberTabCtrl,
                  children: [
                    ModList(communitySlug: widget.communitySlug),
                    BannedList(communitySlug: widget.communitySlug),
                    MutedList(communitySlug: widget.communitySlug),
                  ],
                ),
        ),
      ],
    );
  }
}
