import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'theme/app_theme.dart';

import 'core/security_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SafeKeyApp(),
    ),
  );
}

class SafeKeyApp extends ConsumerStatefulWidget {
  const SafeKeyApp({super.key});

  @override
  ConsumerState<SafeKeyApp> createState() => _SafeKeyAppState();
}

class _SafeKeyAppState extends ConsumerState<SafeKeyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial auth request if started locked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(securityProvider)) {
        ref.read(securityProvider.notifier).authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(securityProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      final isLocked = ref.read(securityProvider);
      if (isLocked) {
        ref.read(securityProvider.notifier).authenticate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(securityProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SafeKey',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (isLocked)
              Material(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 80, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            ref.read(securityProvider.notifier).authenticate();
                          },
                          child: const Text('Unlock'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
