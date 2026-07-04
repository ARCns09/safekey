import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/add_account/add_account_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/export_screen.dart';
import '../database/database.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddAccountScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) {
        final isGoogleImport = state.uri.queryParameters['mode'] == 'google';
        return ScannerScreen(isGoogleImport: isGoogleImport);
      },
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) {
        final accounts = state.extra as List<Account>? ?? [];
        return ExportScreen(accounts: accounts);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
