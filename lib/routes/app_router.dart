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

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        currentIndex: _getCurrentIndex(location),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 24),
            activeIcon: Icon(Icons.explore, size: 24),
            label: 'DISCOVER',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined, size: 24),
            activeIcon: Icon(Icons.article, size: 24),
            label: 'FEED',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            activeIcon: Icon(Icons.settings, size: 24),
            label: 'SETTINGS',
          ),
        ],
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