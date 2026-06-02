import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/unread_count_provider.dart';
import 'inbox_notifications_tab.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isMod = false;
  bool _modCheckDone = false;

  @override
  void initState() {
    super.initState();
    // Start with 5 tabs; rebuild with 6 once mod status is confirmed
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        ref.read(unreadCountProvider.notifier).refresh();
      }
    });
    _checkModStatus();
  }

  Future<void> _checkModStatus() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(QueryOptions(
        document: gql(kMyCommunities),
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      if (!mounted) return;
      final communities = (result.data?['myCommunities'] as List?) ?? [];
      final isMod = communities
          .any((c) => (c as Map<String, dynamic>)['isModerator'] == true);
      // Rebuild controller with correct length
      final newLength = isMod ? 6 : 5;
      final oldCtrl = _tabCtrl;
      _tabCtrl = TabController(length: newLength, vsync: this)
        ..addListener(() {
          if (!_tabCtrl.indexIsChanging) {
            ref.read(unreadCountProvider.notifier).refresh();
          }
        });
      oldCtrl.dispose();
      setState(() {
        _isMod = isMod;
        _modCheckDone = true;
      });
    } catch (_) {
      if (mounted) setState(() => _modCheckDone = true);
    }
  }

  int get _tabLength => _isMod ? 6 : 5;
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = ref.watch(unreadCountProvider);

    if (!_modCheckDone) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Inbox',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Inbox',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Notification preferences',
            onPressed: () => context.push('/notification-preferences'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            const Tab(text: 'Unread'),
            const Tab(text: 'Mentions'),
            const Tab(text: 'Post replies'),
            const Tab(text: 'Comment replies'),
            if (_isMod) const Tab(text: 'Modmail'),
          ],
          labelColor: DesignTokens.primary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          InboxNotificationsTab(onlyUnread: false),
          InboxNotificationsTab(onlyUnread: true),
          InboxNotificationsTab(notifType: 'post_mention'),
          InboxNotificationsTab(notifType: 'post_reply'),
          InboxNotificationsTab(notifType: 'comment_reply'),
          if (_isMod) _buildModmailTab(),
        ],
      ),
    );
  }

  Widget _buildModmailTab() {
    return Query(
      options: QueryOptions(
        document: gql(kMyCommunities),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (communities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Join a community to access modmail',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        final modCommunities = communities
            .where((c) => (c as Map<String, dynamic>)['isModerator'] == true)
            .map((c) => c as Map<String, dynamic>)
            .toList();
        if (modCommunities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('You are not a moderator of any community',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: modCommunities.length,
          itemBuilder: (_, i) {
            final c = modCommunities[i];
            return GestureDetector(
              onTap: () => context.push(
                '/modmail-list/${c['slug']}',
                extra: {
                  'communitySlug': c['slug'].toString(),
                  'communityName':
                      c['name']?.toString() ?? c['slug'].toString(),
                },
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? DesignTokens.darkSurface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DesignTokens.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.mail_outline_rounded,
                          color: DesignTokens.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('y/${c['name']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('${c['memberCount']} members',
                              style: const TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: DesignTokens.textTertiary),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
