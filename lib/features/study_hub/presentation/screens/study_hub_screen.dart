import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studyapp/features/study_hub/presentation/screens/study_materials_tab.dart';
import 'package:studyapp/features/study_hub/presentation/screens/study_quizzes_tab.dart';
import 'package:studyapp/features/study_hub/presentation/screens/study_tools_tab.dart';

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
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          StudyMaterialsTab(dark: dark),
          StudyQuizzesTab(dark: dark),
          StudyToolsTab(dark: dark),
        ],
      ),
    );
  }
}
