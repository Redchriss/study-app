import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/design_tokens.dart';
import 'core/widgets/nav_item.dart';
import 'core/widgets/centre_ai_button.dart';
import 'features/notifications/presentation/providers/unread_count_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _onDestinationSelected(BuildContext context, int index) {
    navigationShell.goBranch(index,
        initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final unreadCount = ref.watch(unreadCountProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Leave?',
                style: TextStyle(fontWeight: FontWeight.w800)),
            content: const Text('Your progress is saved. Come back anytime!'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Stay')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit',
                    style: TextStyle(color: DesignTokens.error)),
              ),
            ],
          ),
        );
        if (shouldExit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  // Tab 0: Feed (with unread badge)
                  NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Feed',
                    isSelected: currentIndex == 0,
                    badgeCount: unreadCount,
                    onTap: () => _onDestinationSelected(context, 0),
                  ),
                  // Tab 1: Study
                  NavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'Study',
                    isSelected: currentIndex == 1,
                    onTap: () => _onDestinationSelected(context, 1),
                  ),
                  // Centre: Agent
                  CentreAiButton(
                    isSelected: false,
                    onTap: () => context.push('/ai-tutor'),
                  ),
                  // Tab 2: Dashboard
                  NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: currentIndex == 2,
                    onTap: () => _onDestinationSelected(context, 2),
                  ),
                  // Tab 3: Profile
                  NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: currentIndex == 3,
                    onTap: () => _onDestinationSelected(context, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
