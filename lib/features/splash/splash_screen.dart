import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Add a slight delay for smooth transition and showing the splash
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 100, color: Colors.white)
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            const Text('SafeKey', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          ],
        ),
      ),
    );
  }
}
