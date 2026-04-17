import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';
import 'package:squirrel_play/presentation/blocs/home/home_bloc.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/pages/gamepad_test_page.dart';
import 'package:squirrel_play/presentation/pages/home_page.dart';
import 'package:squirrel_play/presentation/pages/library_page.dart';
import 'package:squirrel_play/presentation/pages/settings_page.dart';
import 'package:squirrel_play/presentation/navigation/gamepad_hint_provider.dart';
import 'package:squirrel_play/presentation/widgets/app_shell.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_nav_bar.dart';
import 'package:squirrel_play/presentation/widgets/top_bar.dart';

import 'package:squirrel_play/app/di.dart';

/// Application router configuration using GoRouter.
///
/// Defines all routes for the application:
/// - `/` → HomePage
/// - `/library` → LibraryPage
/// - `/settings` → SettingsPage
///
/// Uses ShellRoute to provide a persistent TopBar across all pages:
/// - TopBar is created once and persists during navigation
/// - Page content animates independently (fade + slide)
/// - TopBar stays static during page transitions
///
/// Includes navigation observer for focus management:
/// - Clears focus history on route change
/// - Clears row/grid registrations on route change
/// - Resets focus to first element on new page
///
/// Page transitions use fade + slide animation (300ms enter, 200ms exit).
class AppRouter {
  AppRouter._();

  /// The root navigator key.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// The GoRouter configuration.
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // ShellRoute provides persistent TopBar across all pages
      ShellRoute(
        observers: [
          // Navigation observer for focus management within the shell
          // This ensures focus resets on in-shell navigation
          _FocusManagementNavigatorObserver(),
        ],
        builder: (context, state, child) {
          return Scaffold(
            body: GamepadHintProviderWrapper(
              child: Column(
                children: [
                  // TopBar - persistent across navigation (not recreated on page change)
                  // Wrapped with QuickScanBloc for refresh functionality
                  BlocProvider(
                    create: (context) => getIt<QuickScanBloc>(),
                    child: const TopBar(),
                  ),
                  // Page content - changes during navigation with transition animation
                  Expanded(child: child),
                  // Gamepad navigation hints - persistent bottom bar
                  const GamepadNavBar(),
                ],
              ),
            ),
          );
        },
        routes: [
          // Home route
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: AppShell(
                body: BlocProvider(
                  create: (context) => HomeBloc(
                    homeRepository: getIt<HomeRepository>(),
                    gameRepository: getIt(),
                    metadataRepository: getIt<MetadataRepository>(),
                    gameLauncher: getIt<GameLauncher>(),
                  )..add(const HomeLoadRequested()),
                  child: const HomePage(),
                ),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Fade + slide animation (content area only, TopBar stays static)
                const begin = Offset(0.0, 0.05);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                final tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                final offsetAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          ),

          // Library route
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AppShell(
                body: LibraryPage(),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Fade + slide animation (content area only, TopBar stays static)
                const begin = Offset(0.05, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                final tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                final offsetAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          ),

          // Settings route
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AppShell(
                body: SettingsPage(),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Fade + slide animation (content area only, TopBar stays static)
                const begin = Offset(0.0, 0.05);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                final tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                final offsetAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          ),

          // Gamepad Test route (sibling to /settings)
          GoRoute(
            path: '/settings/gamepad-test',
            name: 'gamepad-test',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AppShell(
                body: GamepadTestPage(),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Fade + slide animation (content area only, TopBar stays static)
                const begin = Offset(0.05, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                final tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                final offsetAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Navigator observer that manages focus on route changes.
///
/// On every route change:
/// 1. Clears focus history
/// 2. Clears row/grid registrations
/// 3. After page builds, focus will be set to first available element
class _FocusManagementNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigationChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigationChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _handleNavigationChange();
  }

  void _handleNavigationChange() {
    debugPrint('[AppRouter] Navigation detected, resetting focus state');

    // Clear focus history
    FocusTraversalService.instance.clearHistory();

    // Clear all registrations (rows, grids)
    FocusTraversalService.instance.clearAllRegistrations();

    // Schedule focus reset after frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Focus will be set to first available element when pages register
      // their focus nodes in initState -> addPostFrameCallback
      debugPrint('[AppRouter] Focus state reset complete');
    });
  }
}
