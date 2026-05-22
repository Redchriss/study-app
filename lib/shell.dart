import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/design_tokens.dart';
import 'widgets/nav_item.dart';
import 'widgets/centre_ai_button.dart';

/// Main app shell with a 5-tab bottom nav.
/// The centre tab is the AI Tutor — prominent and always accessible.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/materials')) return 1;
    if (location.startsWith('/ai-tutor')) return 2;
    if (location.startsWith('/circles')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        context.go('/materials');
        return;
      case 2:
        context.go('/ai-tutor');
        return;
      case 3:
        context.go('/circles');
        return;
      case 4:
        context.go('/profile');
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
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
        
        // If we are not on the home tab, go to home tab instead of exiting
        if (currentIndex != 0) {
          context.go('/home');
          return;
        }

        // On the home tab — ask before exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Leave Yaza?', style: TextStyle(fontWeight: FontWeight.w800)),
            content: const Text('Your progress is saved. Come back anytime!'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit', style: TextStyle(color: DesignTokens.error)),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
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
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: 'Study',
                  isSelected: currentIndex == 1,
                  onTap: () => _onDestinationSelected(context, 1),
                ),
                CentreAiButton(
                  isSelected: currentIndex == 2,
                  onTap: () => _onDestinationSelected(context, 2),
                ),
                NavItem(
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_2_rounded,
                  label: 'Circles',
                  isSelected: currentIndex == 3,
                  onTap: () => _onDestinationSelected(context, 3),
                ),
                NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                  onTap: () => _onDestinationSelected(context, 4),
                ),
              ],
            ),
          ),
        ),
        ), // Container
      ), // Scaffold
    ); // PopScope
  }
}


