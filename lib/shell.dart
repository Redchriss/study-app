import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/design_tokens.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => _onDestinationSelected(context, 0),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: 'Study',
                  isSelected: currentIndex == 1,
                  onTap: () => _onDestinationSelected(context, 1),
                ),
                // Centre AI button
                _CentreAiButton(
                  isSelected: currentIndex == 2,
                  onTap: () => _onDestinationSelected(context, 2),
                ),
                _NavItem(
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_2_rounded,
                  label: 'Circles',
                  isSelected: currentIndex == 3,
                  onTap: () => _onDestinationSelected(context, 3),
                ),
                _NavItem(
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isSelected ? scheme.primary : DesignTokens.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreAiButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CentreAiButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.9),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFF7C4DFF)
                    : DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
