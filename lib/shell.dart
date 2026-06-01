import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/design_tokens.dart';
import 'widgets/nav_item.dart';
import 'widgets/centre_post_button.dart';
import 'features/circles/presentation/screens/create_post_screen.dart';
import 'features/notifications/presentation/providers/unread_count_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _onDestinationSelected(BuildContext context, int index) {
    navigationShell.goBranch(index);
  }

  void _onPostTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: CreatePostScreen(),
      ),
    );
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
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
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
                  NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => _onDestinationSelected(context, 0),
                  ),
                  NavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Discover',
                    isSelected: currentIndex == 1,
                    onTap: () => _onDestinationSelected(context, 1),
                  ),
                  CentrePostButton(
                    onTap: () => _onPostTap(context),
                  ),
                  Stack(
                    children: [
                      NavItem(
                        icon: Icons.inbox_outlined,
                        activeIcon: Icons.inbox_rounded,
                        label: 'Inbox',
                        isSelected: currentIndex == 2,
                        onTap: () => _onDestinationSelected(context, 2),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: DesignTokens.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
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
