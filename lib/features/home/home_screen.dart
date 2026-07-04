import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../widgets/totp_account_card.dart';
import '../../database/database.dart';
import 'package:base32/base32.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  Set<int> _selectedIds = {};

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _togglePinSelectedAccounts(bool pin) async {
    final accounts = ref.read(watchAccountsProvider).value ?? [];
    final toUpdate = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
    for (final acc in toUpdate) {
      await ref.read(accountRepositoryProvider).updateAccount(acc.copyWith(isPinned: pin));
    }
    setState(() {
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toUpdate.length} account(s) ${pin ? 'pinned' : 'unpinned'}')),
      );
    }
  }

  Future<void> _deleteSelectedAccounts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Accounts'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} account(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final accounts = ref.read(watchAccountsProvider).value ?? [];
      final toDelete = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
      for (final acc in toDelete) {
        await ref.read(accountRepositoryProvider).deleteAccount(acc);
      }
      setState(() {
        _selectedIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${toDelete.length} account(s) deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortOrder = ref.watch(sortOrderProvider);
    
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: isSelectionMode 
        ? AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedIds.clear()),
            ),
            title: Text('${_selectedIds.length} selected'),
            actions: [
              IconButton(
                icon: const Icon(Icons.push_pin),
                tooltip: 'Pin Selected',
                onPressed: () => _togglePinSelectedAccounts(true),
              ),
              IconButton(
                icon: const Icon(Icons.push_pin_outlined),
                tooltip: 'Unpin Selected',
                onPressed: () => _togglePinSelectedAccounts(false),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: 'Export Selected',
                onPressed: () {
                  final accounts = ref.read(watchAccountsProvider).value ?? [];
                  final toExport = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
                  setState(() => _selectedIds.clear());
                  context.push('/export', extra: toExport);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Selected',
                onPressed: _deleteSelectedAccounts,
              ),
            ],
          )
        : AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _isSearching
                ? TextField(
                    key: const ValueKey('search'),
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search accounts...',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  )
                : const Text('SafeKey', key: ValueKey('title'), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort/Group',
              onSelected: (value) {
                ref.read(sortOrderProvider.notifier).setSortOrder(value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'recent',
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text('Recently Added', style: TextStyle(fontWeight: sortOrder == 'recent' ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      const Icon(Icons.sort_by_alpha, size: 20),
                      const SizedBox(width: 8),
                      Text('Alphabetical', style: TextStyle(fontWeight: sortOrder == 'name' ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'issuer',
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, size: 20),
                      const SizedBox(width: 8),
                      Text('Group by Issuer', style: TextStyle(fontWeight: sortOrder == 'issuer' ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
        ],
      ),
      body: ref.watch(watchAccountsProvider).when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add a new account',
                    style: TextStyle(color: Colors.grey),
                  ),
                ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
              ),
            );
          }
          var filteredAccounts = accounts.where((acc) {
            return acc.issuer.toLowerCase().contains(_searchQuery) ||
                   acc.accountName.toLowerCase().contains(_searchQuery);
          }).toList();
          
          if (sortOrder == 'name') {
            filteredAccounts.sort((a, b) => a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase()));
          } else if (sortOrder == 'issuer') {
            filteredAccounts.sort((a, b) => a.issuer.toLowerCase().compareTo(b.issuer.toLowerCase()));
          } else {
            // 'recent' (default), descending ID
            filteredAccounts.sort((a, b) => b.id.compareTo(a.id));
          }

          var pinned = filteredAccounts.where((a) => a.isPinned).toList();
          var unpinned = filteredAccounts.where((a) => !a.isPinned).toList();
          filteredAccounts = [...pinned, ...unpinned];

          if (filteredAccounts.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isNotEmpty ? 'No matches found' : 'No accounts yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              final account = filteredAccounts[index];
              return Dismissible(
                key: ValueKey(account.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  if (isSelectionMode) return false; // Disable swipe in selection mode
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: Text('Are you sure you want to delete ${account.accountName}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref.read(accountRepositoryProvider).deleteAccount(account);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${account.accountName} deleted')),
                  );
                },
                child: TotpAccountCard(
                  account: account,
                  isSelected: _selectedIds.contains(account.id),
                  onLongPress: () {
                    if (!_isSearching) _toggleSelection(account.id);
                  },
                  onTap: isSelectionMode ? () => _toggleSelection(account.id) : null,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAccountOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR Code'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scanner');
                },
              ),
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('Import from Google Authenticator'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scanner?mode=google');
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Paste URI'),
                onTap: () {
                  Navigator.pop(context);
                  _showPasteUriDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Import from File'),
                onTap: () {
                  Navigator.pop(context);
                  _importFromFile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text('Enter Secret Manually'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showPasteUriDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste URI'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'otpauth://totp/...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processUri(controller.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUri(String uriString) async {
    if (!uriString.startsWith('otpauth://')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URI format')));
      return;
    }
    // We will parse it and add it
    // Wait, the logic is in ScannerScreen. Let's move it here or just duplicate it for now.
    try {
      final uri = Uri.parse(uriString);
      final queryParams = uri.queryParameters;
      final secret = queryParams['secret']?.toUpperCase().replaceAll(' ', '') ?? '';
      
      if (secret.isEmpty) throw Exception('No secret found');
      
      String issuer = queryParams['issuer'] ?? '';
      String accountName = '';
      
      final pathParts = uri.path.substring(1).split(':');
      if (pathParts.length > 1) {
        if (issuer.isEmpty) issuer = Uri.decodeComponent(pathParts[0]);
        accountName = Uri.decodeComponent(pathParts.sublist(1).join(':'));
      } else if (pathParts.isNotEmpty) {
        accountName = Uri.decodeComponent(pathParts[0]);
      }
      
      if (issuer.isEmpty) issuer = 'Unknown';
      if (accountName.isEmpty) accountName = 'Unknown';

      final algorithm = queryParams['algorithm'] ?? 'SHA1';
      final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
      
      final newAccount = AccountsCompanion.insert(
        issuer: issuer,
        accountName: accountName,
        secret: secret,
        algorithm: drift.Value(algorithm),
        digits: drift.Value(digits),
      );

      await ref.read(accountRepositoryProvider).insertAccount(newAccount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account added successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse URI')));
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'files',
      );
      final XFile? xFile = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (xFile == null) return;
      final file = File(xFile.path);
      final extension = xFile.name.split('.').last.toLowerCase();

      if (extension == 'sqlite') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Database'),
            content: const Text('Warning: Restoring a database backup will overwrite all current accounts. This backup must have been created on this exact device (encryption key must match). Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final dbFolder = await getApplicationDocumentsDirectory();
          final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
          
          await ref.read(databaseProvider).close();
          await file.copy(dbPath);
          ref.invalidate(databaseProvider);
          
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database restored!')));
        }
        return;
      }

      // Handle JSON/TXT
      final content = await file.readAsString();
      
      if (content.trim().startsWith('{')) {
        // Try parsing as JSON
        final Map<String, dynamic> json = jsonDecode(content);
        
        // Aegis
        if (json.containsKey('version') && json.containsKey('db')) {
          final entries = json['db']['entries'] as List?;
          if (entries != null) {
            int addedCount = 0;
            for (final entry in entries) {
              if (entry['type'] != 'totp') continue;
              final info = entry['info'];
              final secret = info['secret'];
              final issuer = entry['issuer'] ?? 'Unknown';
              final accountName = entry['name'] ?? 'Unknown';
              final algo = info['algo'] ?? 'SHA1';
              final digits = info['digits'] ?? 6;
              
              final newAccount = AccountsCompanion.insert(
                issuer: issuer,
                accountName: accountName,
                secret: secret,
                algorithm: drift.Value(algo.toString().toUpperCase()),
                digits: drift.Value(digits),
              );
              await ref.read(accountRepositoryProvider).insertAccount(newAccount);
              addedCount++;
            }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $addedCount accounts from Aegis backup!')));
            return;
          }
        }
        
        // 2FAS
        if (json.containsKey('services') && json['services'] is List) {
          final services = json['services'] as List;
          int addedCount = 0;
          for (final service in services) {
            final secret = service['secret'];
            if (secret == null) continue;
            final otp = service['otp'] ?? {};
            final issuer = service['name'] ?? 'Unknown';
            final algo = otp['algorithm'] ?? 'SHA1';
            final digits = otp['digits'] ?? 6;
            
            final newAccount = AccountsCompanion.insert(
              issuer: issuer,
              accountName: issuer,
              secret: secret,
              algorithm: drift.Value(algo.toString().toUpperCase()),
              digits: drift.Value(digits),
            );
            await ref.read(accountRepositoryProvider).insertAccount(newAccount);
            addedCount++;
          }
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $addedCount accounts from 2FAS backup!')));
          return;
        }
      }

      // Try parsing as raw otpauth:// URIs line by line
      final lines = content.split('\n');
      int addedCount = 0;
      for (final line in lines) {
        final uriString = line.trim();
        if (uriString.startsWith('otpauth://')) {
          try {
            final uri = Uri.parse(uriString);
            final queryParams = uri.queryParameters;
            final secret = queryParams['secret']?.toUpperCase().replaceAll(' ', '') ?? '';
            if (secret.isEmpty) continue;
            String issuer = queryParams['issuer'] ?? 'Unknown';
            String accountName = 'Unknown';
            final pathParts = uri.path.substring(1).split(':');
            if (pathParts.length > 1) {
              if (issuer == 'Unknown') issuer = Uri.decodeComponent(pathParts[0]);
              accountName = Uri.decodeComponent(pathParts.sublist(1).join(':'));
            } else if (pathParts.isNotEmpty) {
              accountName = Uri.decodeComponent(pathParts[0]);
            }
            final algo = queryParams['algorithm'] ?? 'SHA1';
            final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
            final newAccount = AccountsCompanion.insert(
              issuer: issuer,
              accountName: accountName,
              secret: secret,
              algorithm: drift.Value(algo),
              digits: drift.Value(digits),
            );
            await ref.read(accountRepositoryProvider).insertAccount(newAccount);
            addedCount++;
          } catch (_) {}
        }
      }

      if (addedCount > 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $addedCount accounts from URIs!')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recognizable accounts found in file')));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import file: $e')));
    }
  }
}
