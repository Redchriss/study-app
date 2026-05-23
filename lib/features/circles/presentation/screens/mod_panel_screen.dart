import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mod_panel_reports_tab.dart';
import 'mod_panel_mod_log_tab.dart';

class ModPanelScreen extends ConsumerWidget {
  final String communitySlug;

  const ModPanelScreen({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('y/$communitySlug mod'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reports', icon: Icon(Icons.flag_outlined)),
              Tab(text: 'Mod Log', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ModPanelReportsTab(communitySlug: communitySlug),
            ModPanelModLogTab(communitySlug: communitySlug),
          ],
        ),
      ),
    );
  }
}
