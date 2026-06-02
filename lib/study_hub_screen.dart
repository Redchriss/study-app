import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'core/graphql/queries/queries.dart';
import 'core/theme/design_tokens.dart';
import 'core/widgets/widgets.dart';
import 'core/errors/app_exception.dart';
import 'features/materials/presentation/widgets/material_card.dart';
import 'features/quizzes/presentation/screens/quiz_card.dart';

/// Study Hub — tab 1 of the bottom nav.
/// Shows Materials feed + Popular Quizzes in one scrollable screen.
class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Study',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Tools'),
          ],
          labelColor: DesignTokens.primary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload material',
            onPressed: () => context.push('/upload-material'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _MaterialsTab(dark: dark),
          _QuizzesTab(dark: dark),
          _ToolsTab(dark: dark),
        ],
      ),
    );
  }
}

// ── Materials tab ──────────────────────────────────────────────────────────────
class _MaterialsTab extends StatefulWidget {
  final bool dark;
  const _MaterialsTab({required this.dark});

  @override
  State<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<_MaterialsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';
  String _type = 'all';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Query(
      options: QueryOptions(
        document: gql(kMaterials),
        variables: {'limit': 50},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        final rawMaterials = (result.data?['materials'] as List?) ?? [];
        final materials = rawMaterials
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) {
          if (_type != 'all' &&
              (m['contentType'] ?? '').toString().toLowerCase() != _type) {
            return false;
          }
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            return (m['title'] ?? '').toString().toLowerCase().contains(q) ||
                (m['subject']?['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q);
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _search = _ctrl.text = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: widget.dark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            _TypeFilterBar(
                selected: _type, onSelect: (t) => setState(() => _type = t)),
            Expanded(
              child: result.isLoading && rawMaterials.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerBox(
                              height: 108, radius: DesignTokens.radiusLg)),
                    )
                  : result.hasException && rawMaterials.isEmpty
                      ? ErrorState(
                          message: graphQLErrorMessage(
                              result.exception, 'Could not load materials.'),
                          onRetry: () => refetch?.call(),
                        )
                      : materials.isEmpty
                          ? const EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No materials found',
                              subtitle: 'Try adjusting your filters.')
                          : RefreshIndicator(
                              onRefresh: () async => refetch?.call(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                itemCount: materials.length,
                                itemBuilder: (_, i) => MaterialCard(
                                  material: materials[i],
                                  dark: widget.dark,
                                  index: i,
                                  onTap: () => context.push(
                                      '/materials/${materials[i]['slug']}'),
                                ),
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _TypeFilterBar({required this.selected, required this.onSelect});

  static const _filters = [
    ('all', 'All'),
    ('pdf', 'PDF'),
    ('text', 'Text'),
    ('video', 'Video'),
    ('youtube', 'YouTube'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _filters.map((f) {
          final (val, label) = f;
          final sel = selected == val;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : DesignTokens.textSecondary)),
              selected: sel,
              onSelected: (_) => onSelect(val),
              selectedColor: DesignTokens.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                  color: sel
                      ? DesignTokens.primary
                      : DesignTokens.border.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Quizzes tab ────────────────────────────────────────────────────────────────
class _QuizzesTab extends StatelessWidget {
  final bool dark;
  const _QuizzesTab({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Query(
      options:
          QueryOptions(document: gql(kQuizzes), variables: const {'limit': 50}),
      builder: (result, {fetchMore, refetch}) {
        final quizzes = (result.data?['quizzes'] as List?) ?? [];

        if (result.isLoading && quizzes.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(height: 96, radius: DesignTokens.radiusXl)),
          );
        }
        if (result.hasException && quizzes.isEmpty) {
          return ErrorState(
            message: graphQLErrorMessage(
                result.exception, 'Could not load quizzes.'),
            onRetry: () => refetch?.call(),
          );
        }
        if (quizzes.isEmpty) {
          return const EmptyState(
            icon: Icons.quiz_outlined,
            title: 'No quizzes yet',
            subtitle: 'Check back soon.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: quizzes.length,
            itemBuilder: (_, i) => QuizCard(
              quiz: quizzes[i] as Map<String, dynamic>,
              dark: dark,
              index: i,
            ),
          ),
        );
      },
    );
  }
}

// ── Tools tab ─────────────────────────────────────────────────────────────────
class _ToolsTab extends StatelessWidget {
  final bool dark;
  const _ToolsTab({required this.dark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _ToolCard(
          icon: Icons.document_scanner_rounded,
          color: const Color(0xFFFFB300),
          title: 'AI Paper Solver',
          subtitle: 'Snap or upload a past paper — AI solves it step by step',
          badge: 'AI • 1 credit',
          onTap: () => context.push('/scanner'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.emoji_events_rounded,
          color: DesignTokens.warning,
          title: 'Leaderboard',
          subtitle: 'See top learners and contributors',
          onTap: () => context.push('/leaderboard'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.history_rounded,
          color: DesignTokens.info,
          title: 'Study History',
          subtitle: 'Review your quiz attempts and study sessions',
          onTap: () => context.push('/history'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.bookmark_rounded,
          color: DesignTokens.secondary,
          title: 'Bookmarks',
          subtitle: 'Materials you saved for later',
          onTap: () => context.push('/bookmarks'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.library_books_rounded,
          color: DesignTokens.primary,
          title: 'Past Papers Library',
          subtitle: 'Browse and download past exam papers',
          onTap: () => context.push('/paper-library'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.upload_file_rounded,
          color: DesignTokens.accent,
          title: 'My Uploads',
          subtitle: 'Manage materials you have uploaded',
          onTap: () => context.push('/my-uploads'),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: dark
                  ? DesignTokens.darkBorder
                  : DesignTokens.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge!,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
