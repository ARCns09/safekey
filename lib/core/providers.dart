import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../repositories/account_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepository(db);
});

final watchAccountsProvider = StreamProvider<List<Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAllAccounts();
});

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _loadTheme(prefs);
  }

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final mode = prefs.getString('theme_mode');
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('theme_mode', mode.name);
  }
}

final hideCodesProvider = NotifierProvider<HideCodesNotifier, bool>(HideCodesNotifier.new);

class HideCodesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hide_codes') ?? false;
  }

  void toggle(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('hide_codes', value);
  }
}

final sortOrderProvider = NotifierProvider<SortOrderNotifier, String>(SortOrderNotifier.new);

class SortOrderNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('sort_order') ?? 'recent'; // 'recent', 'issuer', 'name'
  }

  void setSortOrder(String order) {
    state = order;
    ref.read(sharedPreferencesProvider).setString('sort_order', order);
  }
}
