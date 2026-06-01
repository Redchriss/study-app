import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mod_panel_reports_tab.dart';
import 'mod_panel_members_tab.dart';
import 'mod_panel_modmail_tab.dart';
import 'mod_panel_mod_log_tab.dart';
import 'mod_panel_settings_tab.dart';

class ModPanelScreen extends ConsumerWidget {
  final String communitySlug;

  const ModPanelScreen({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('y/$communitySlug mod'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Queue', icon: Icon(Icons.flag_outlined)),
              Tab(text: 'Mod Log', icon: Icon(Icons.history)),
              Tab(text: 'Members', icon: Icon(Icons.people_outline)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
              Tab(text: 'Modmail', icon: Icon(Icons.mail_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ModPanelReportsTab(communitySlug: communitySlug),
            ModPanelModLogTab(communitySlug: communitySlug),
            ModPanelMembersTab(communitySlug: communitySlug),
            ModPanelSettingsTab(communitySlug: communitySlug),
            ModPanelModmailTab(communitySlug: communitySlug),
          ],
        ),
      ),
    );
  }
}
