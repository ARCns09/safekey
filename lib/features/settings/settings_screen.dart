import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
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

    final accountsAsync = ref.watch(watchAccountsProvider);
    final accounts = accountsAsync.value ?? [];
    
    final int totalAccounts = accounts.length;
    final int pinnedAccounts = accounts.where((a) => a.isPinned).length;
    final int hiddenAccounts = isHideCodesEnabled ? totalAccounts : 0; // Simple approximation

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Statistics Dashboard
          _buildSectionHeader(context, 'Dashboard', Icons.analytics_outlined),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, 'Total', totalAccounts.toString(), Icons.format_list_numbered),
                  _buildStatItem(context, 'Pinned', pinnedAccounts.toString(), Icons.push_pin),
                  _buildStatItem(context, 'Hidden', hiddenAccounts.toString(), Icons.visibility_off),
                ],
              ),
            ),
          ),

          // Appearance
          _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
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
              ],
            ),
          ),

          // Security
          _buildSectionHeader(context, 'Security', Icons.security),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('App Lock'),
                  subtitle: const Text('Require authentication to open'),
                  value: isLockEnabled,
                  onChanged: (val) {
                    ref.read(securityProvider.notifier).toggleLock(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off),
                  title: const Text('Hide codes by default'),
                  subtitle: const Text('Tap card to reveal code'),
                  value: isHideCodesEnabled,
                  onChanged: (val) {
                    ref.read(hideCodesProvider.notifier).toggle(val);
                  },
                ),
              ],
            ),
          ),

          // Data & Accounts
          _buildSectionHeader(context, 'Accounts & Data', Icons.data_usage),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sort),
                  title: const Text('Sort Order'),
                  trailing: DropdownButton<String>(
                    value: sortOrder,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'custom', child: Text('Custom (Drag)')),
                      DropdownMenuItem(value: 'recent', child: Text('Recent')),
                      DropdownMenuItem(value: 'name', child: Text('A-Z')),
                      DropdownMenuItem(value: 'issuer', child: Text('Issuer')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(sortOrderProvider.notifier).setSortOrder(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Export Accounts (QR)'),
                  subtitle: const Text('Export as QR codes'),
                  leading: const Icon(Icons.qr_code_scanner),
                  onTap: () {
                    if (accounts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts to export.')));
                      return;
                    }
                    context.push('/export', extra: accounts);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Backup Database'),
                  subtitle: const Text('Export safekey.sqlite file'),
                  leading: const Icon(Icons.save_alt),
                  onTap: () => _exportDatabase(context),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Restore Database'),
                  subtitle: const Text('Import safekey.sqlite file'),
                  leading: const Icon(Icons.file_upload),
                  onTap: () => _importFromFile(context, ref),
                ),
              ],
            ),
          ),
          
          // About
          _buildSectionHeader(context, 'About', Icons.info_outline),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('SafeKey Version'),
                  trailing: const Text('2.1.0', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No database found to export.')));
        }
        return;
      }
      
      final String fileName = 'safekey_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite';
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, fileName));
      await dbFile.copy(tempFile.path);
      
      final XFile xFile = XFile(tempFile.path);
      
      final result = await Share.shareXFiles([xFile], text: 'SafeKey Database Backup');
      
      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database exported successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    try {
      const typeGroup = XTypeGroup(label: 'SQLite', extensions: ['sqlite', 'db']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
        final walPath = p.join(dbFolder.path, 'safekey.sqlite-wal');
        final shmPath = p.join(dbFolder.path, 'safekey.sqlite-shm');
        final journalPath = p.join(dbFolder.path, 'safekey.sqlite-journal');
        
        // Delete temporary SQLite files to avoid restoring deleted accounts
        if (await File(walPath).exists()) await File(walPath).delete();
        if (await File(shmPath).exists()) await File(shmPath).delete();
        if (await File(journalPath).exists()) await File(journalPath).delete();
        
        // Overwrite main db file
        await File(file.path).copy(dbPath);
        
        ref.invalidate(databaseProvider);
        // also invalidate the account repo provider and accounts watch provider
        ref.invalidate(accountRepositoryProvider);
        ref.invalidate(watchAccountsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database imported successfully.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
