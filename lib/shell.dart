import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/design_tokens.dart';

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

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/materials');
      case 2: context.go('/scanner');
      case 3: context.go('/circles');
      case 4: context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Materials'),
          BottomNavigationBarItem(
            icon: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: DesignTokens.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
            ),
            label: 'Scanner',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Circles'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
