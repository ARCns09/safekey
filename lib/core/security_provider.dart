import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'providers.dart';

final securityProvider = NotifierProvider<SecurityNotifier, bool>(SecurityNotifier.new);

final lockEnabledProvider = Provider<bool>((ref) {
  ref.watch(securityProvider);
  return ref.read(securityProvider.notifier).isLockEnabled;
});

class SecurityNotifier extends Notifier<bool> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  bool build() {
    if (isLockEnabled) return true;
    return false;
  }

  bool get isLockEnabled {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('app_locked') ?? false;
  }

  Future<void> toggleLock(bool enable) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('app_locked', enable);
    if (enable) {
      state = true;
      authenticate();
    } else {
      state = false;
    }
  }

  void lock() {
    if (isLockEnabled) {
      state = true;
    }
  }

  Future<void> authenticate() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      state = false; // Bypass auth on unsupported desktop platforms
      return;
    }
    
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock SafeKey',
      );
      if (authenticated) {
        state = false;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> authenticateForAction(String reason) async {
    if (!isLockEnabled) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      return false;
    }
  }
}
