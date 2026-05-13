import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main app shell: Material 3 [NavigationBar] with clear hierarchy and
/// a visually distinct Scanner entry (common pattern in consumer apps).
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/materials')) return 1;
    if (location.startsWith('/scanner')) return 2;
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
        context.go('/scanner');
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

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Materials',
          ),
          NavigationDestination(
            icon: _ScannerNavIcon(
              selected: false,
              foreground: scheme.onPrimaryContainer,
              background: scheme.primaryContainer,
            ),
            selectedIcon: _ScannerNavIcon(
              selected: true,
              foreground: scheme.onPrimary,
              background: scheme.primary,
            ),
            label: 'Scanner',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Circles',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ScannerNavIcon extends StatelessWidget {
  const _ScannerNavIcon({
    required this.selected,
    required this.foreground,
    required this.background,
  });

  final bool selected;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: foreground.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        selected ? Icons.document_scanner_rounded : Icons.document_scanner_outlined,
        color: foreground,
        size: 22,
      ),
    );
  }
}
