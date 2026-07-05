import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/add_account/add_account_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/export_screen.dart';
import '../features/home/recovery_codes_screen.dart';
import '../database/database.dart';
import 'package:flutter/material.dart';

CustomTransitionPage buildPageWithDefaultTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuad,
          )),
          child: child,
        ),
      );
    },
  );
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/add',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const AddAccountScreen(),
      ),
    ),
    GoRoute(
      path: '/scanner',
      pageBuilder: (context, state) {
        final isGoogleImport = state.uri.queryParameters['mode'] == 'google';
        return buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: ScannerScreen(isGoogleImport: isGoogleImport),
        );
      },
    ),
    GoRoute(
      path: '/export',
      pageBuilder: (context, state) {
        final accounts = state.extra as List<Account>? ?? [];
        return buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: ExportScreen(accounts: accounts),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/recovery',
      pageBuilder: (context, state) {
        final account = state.extra as Account;
        return buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: RecoveryCodesScreen(account: account),
        );
      },
    ),
  ],
);
