import 'package:flutter/material.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';
import 'search_tabs.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? communitySlug;
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.communitySlug,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _ctrl = TextEditingController();
  String _query = '';
  String _sort = 'relevance';
  String _timeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          HapticService.selection();
          setState(() {});
        }
      });
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    HapticService.lightTap();
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.communitySlug != null
                ? 'Search y/${widget.communitySlug}...'
                : 'Search posts, communities, people...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: dark
                  ? DesignTokens.darkTextTertiary
                  : DesignTokens.textTertiary,
              fontSize: 15,
            ),
          ),
          onSubmitted: (_) => _runSearch(),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _runSearch,
          ),
        ],
        bottom: _query.isEmpty
            ? null
            : TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Communities'),
                  Tab(text: 'People'),
                ],
                labelColor: DesignTokens.primary,
                unselectedLabelColor: DesignTokens.textTertiary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                dividerColor: Colors.transparent,
              ),
      ),
      body: _query.isEmpty
          ? SearchEmptyHint(communitySlug: widget.communitySlug)
          : TabBarView(
              controller: _tabCtrl,
              children: [
                SearchPostsTab(
                  query: _query,
                  sort: _sort,
                  timeFilter: _timeFilter,
                  communitySlug: widget.communitySlug,
                  dark: dark,
                  onSortChanged: (s) => setState(() => _sort = s),
                  onTimeFilterChanged: (t) => setState(() => _timeFilter = t),
                ),
                SearchCommunitiesTab(query: _query, dark: dark),
                SearchPeopleTab(query: _query, dark: dark),
              ],
            ),
    );
  }
}
