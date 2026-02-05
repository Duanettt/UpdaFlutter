import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upda3/features/discover/presentation/discover_screen.dart';
import 'package:upda3/features/feed/presentation/feed_screen.dart';
import 'package:upda3/features/settings/presentation/settings_screen.dart';
import 'package:upda3/common/style/theme.dart';

part 'app_router.g.dart';

// Route paths as constants for type safety
const String discoverPath = '/discover';
const String feedPath = '/feed';
const String settingsPath = '/settings';

/// Main app router with bottom navigation shell
///
/// Uses @riverpod annotation to generate a provider
/// This creates `appRouterProvider` automatically after build_runner
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: discoverPath,
    routes: [
      // Shell route wraps all main screens with bottom nav
      ShellRoute(
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: discoverPath,
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: feedPath,
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: settingsPath,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Main app shell with bottom navigation bar
///
/// Wraps all screens and provides persistent bottom nav
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

/// Bottom navigation bar component
///
/// Highlights current route and handles navigation between main sections
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getCurrentIndex(location);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                isSelected: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
              _NavItem(
                icon: Icons.article_outlined,
                isSelected: currentIndex == 1,
                onTap: () => _onTap(context, 1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                isSelected: currentIndex == 2,
                onTap: () => _onTap(context, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Maps current route path to bottom nav index
  int _getCurrentIndex(String location) {
    if (location.startsWith(discoverPath)) return 0;
    if (location.startsWith(feedPath)) return 1;
    if (location.startsWith(settingsPath)) return 2;
    return 0;
  }

  /// Handles bottom nav taps - navigates to selected route
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(discoverPath);
        break;
      case 1:
        context.go(feedPath);
        break;
      case 2:
        context.go(settingsPath);
        break;
    }
  }
}

/// Individual navigation item with icon and selection state
class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}