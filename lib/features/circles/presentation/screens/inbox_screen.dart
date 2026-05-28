import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'inbox_notifications_tab.dart';
import 'inbox_modmail_tab.dart';

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
    _tabCtrl = TabController(length: 6, vsync: this);
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
      setState(() {
        _isMod = isMod;
        _modCheckDone = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _modCheckDone = true);
      }
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

    return DefaultTabController(
      length: _tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inbox',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          bottom: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: [
              const Tab(text: 'All'),
              const Tab(text: 'Unread'),
              const Tab(text: 'Mentions'),
              const Tab(text: 'Replies'),
              const Tab(text: 'Comment Replies'),
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
            if (_isMod) const InboxModmailTab(),
          ],
        ),
      ),
    );
  }
}
