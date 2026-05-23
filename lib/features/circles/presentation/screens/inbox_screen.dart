import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inbox',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          bottom: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Mentions'),
              Tab(text: 'Replies'),
              Tab(text: 'Comment Replies'),
              Tab(text: 'Modmail'),
            ],
            labelColor: DesignTokens.primary,
            unselectedLabelColor: DesignTokens.textSecondary,
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            InboxNotificationsTab(onlyUnread: false),
            InboxNotificationsTab(onlyUnread: true),
            InboxNotificationsTab(notifType: 'post_mention'),
            InboxNotificationsTab(notifType: 'post_reply'),
            InboxNotificationsTab(notifType: 'comment_reply'),
            InboxModmailTab(),
          ],
        ),
      ),
    );
  }
}
