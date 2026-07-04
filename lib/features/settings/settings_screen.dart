import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/providers.dart';
import '../../core/security_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isLockEnabled = ref.watch(lockEnabledProvider);
    final isHideCodesEnabled = ref.watch(hideCodesProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeProvider.notifier).setTheme(mode);
                }
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('App Lock'),
            subtitle: const Text('Require authentication to open SafeKey'),
            value: isLockEnabled,
            onChanged: (val) {
              ref.read(securityProvider.notifier).toggleLock(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Accounts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Hide codes by default'),
            subtitle: const Text('Tap an account card to reveal its code'),
            value: isHideCodesEnabled,
            onChanged: (val) {
              ref.read(hideCodesProvider.notifier).toggle(val);
            },
          ),
          ListTile(
            title: const Text('Sort Order'),
            trailing: DropdownButton<String>(
              value: sortOrder,
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Recently Added')),
                DropdownMenuItem(value: 'name', child: Text('Account Name (A-Z)')),
                DropdownMenuItem(value: 'issuer', child: Text('Issuer (A-Z)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(sortOrderProvider.notifier).setSortOrder(val);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Export All Accounts'),
            subtitle: const Text('Export accounts as standard QR codes'),
            leading: const Icon(Icons.qr_code_scanner),
            onTap: () {
              final accounts = ref.read(watchAccountsProvider).value ?? [];
              if (accounts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts to export.')));
                return;
              }
              context.push('/export', extra: accounts);
            },
          ),
          ListTile(
            title: const Text('Export Database Backup'),
            subtitle: const Text('Export the encrypted safekey.sqlite file'),
            leading: const Icon(Icons.save),
            onTap: () async {
              try {
                final dbFolder = await getApplicationDocumentsDirectory();
                final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
                if (await File(dbPath).exists()) {
                  await Share.shareXFiles([XFile(dbPath)], text: 'SafeKey Encrypted Backup');
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No database found.')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
