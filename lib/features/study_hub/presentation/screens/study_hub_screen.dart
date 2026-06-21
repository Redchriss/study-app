import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../features/study_hub/presentation/screens/study_materials_tab.dart';
import '../../../../features/study_hub/presentation/screens/study_quizzes_tab.dart';
import '../../../../features/study_hub/presentation/screens/study_tools_tab.dart';

class StudyHubScreen extends ConsumerStatefulWidget {
  const StudyHubScreen({super.key});

  @override
  ConsumerState<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends ConsumerState<StudyHubScreen>
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Query(
                options: QueryOptions(document: gql(kMe)),
                builder: (result, {fetchMore, refetch}) {
                  final me = result.data?['me'] as Map?;
                  final profile = me?['profile'] as Map?;
                  final username =
                      me?['username']?.toString() ?? 'Student';
                  final firstName = me?['firstName']?.toString();
                  final displayName = (firstName != null &&
                          firstName.isNotEmpty)
                      ? firstName
                      : username;
                  final streak =
                      (profile?['studyStreak'] as num?)?.toInt() ?? 0;
                  final credits =
                      (profile?['aiCredits'] as num?)?.toInt() ?? 0;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style:
                                    theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (streak > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: DesignTokens.warning
                                  .withValues(alpha: dark ? 0.2 : 0.08),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusMd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    size: 16, color: DesignTokens.warning),
                                const SizedBox(width: 4),
                                Text('$streak',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: DesignTokens.warning,
                                    )),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary
                                .withValues(alpha: dark ? 0.2 : 0.08),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: DesignTokens.primary),
                              const SizedBox(width: 4),
                              Text('$credits',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: DesignTokens.primary,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TabBar(
                controller: _tab,
                tabs: const [
                  Tab(text: 'Materials'),
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Tools'),
                ],
                labelColor: DesignTokens.primary,
                unselectedLabelColor: DesignTokens.textTertiary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: DesignTokens.brandGradient,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                dividerColor: Colors.transparent,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            StudyMaterialsTab(dark: dark),
            StudyQuizzesTab(dark: dark),
            StudyToolsTab(dark: dark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/upload-material'),
        icon: const Icon(Icons.upload_file_rounded, size: 20),
        label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700)),
        tooltip: 'Upload a study material',
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
