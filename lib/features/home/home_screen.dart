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
                if (value == 'select_mode') {
                  // Enter selection mode with first item (or just empty state)
                  setState(() {
                    _selectedIds.clear();
                    // We just need the UI to show selection mode. But it needs an ID to start?
                    // We can just add a dummy ID or modify logic.
                    // Actually, if we just want to allow tapping to select, we can add a boolean `_isSelecting`.
                    // But isSelectionMode is `_selectedIds.isNotEmpty`.
                    // Let's just add the first account to selection to trigger the mode.
                  });
                  final accounts = ref.read(watchAccountsProvider).value ?? [];
                  if (accounts.isNotEmpty) {
                    _toggleSelection(accounts.first.id);
                  }
                } else {
                  ref.read(sortOrderProvider.notifier).setSortOrder(value);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'custom',
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle, size: 20),
                      const SizedBox(width: 8),
                      Text('Custom Order', style: TextStyle(fontWeight: sortOrder == 'custom' ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'select_mode',
                  child: Row(
                    children: [
                      const Icon(Icons.checklist, size: 20),
                      const SizedBox(width: 8),
                      const Text('Select Accounts'),
                    ],
                  ),
                ),
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'SafeKey',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your authenticator is empty.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan your first QR code or manually add an account to get started.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 48),
                      FilledButton.icon(
                        onPressed: () => context.push('/scanner'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => context.push('/add'),
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Add Manually'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuart),
                  ),
                ),
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
          } else if (sortOrder == 'custom') {
            filteredAccounts.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
          } else {
            // 'recent', descending ID
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
          return ReorderableListView.builder(
            buildDefaultDragHandles: false, // We'll trigger drag manually on the card if needed, or long press
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              if (_isSearching) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot reorder while searching')));
                return;
              }
              if (sortOrder != 'custom') {
                ref.read(sortOrderProvider.notifier).setSortOrder('custom');
              }
              
              final currentList = List<Account>.from(filteredAccounts);
              final item = currentList.removeAt(oldIndex);
              currentList.insert(newIndex, item);

              final repo = ref.read(accountRepositoryProvider);
              for (int i = 0; i < currentList.length; i++) {
                final acc = currentList[i];
                if (acc.sortIndex != i) {
                  await repo.updateAccount(acc.copyWith(sortIndex: i));
                }
              }
            },
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
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: TotpAccountCard(
                    account: account,
                    isSelected: _selectedIds.contains(account.id),
                    onLongPress: null, // Disable long press so it doesn't conflict with drag-to-reorder
                    onTap: isSelectionMode ? () => _toggleSelection(account.id) : null,
                  ),
                ),
              ).animate(key: ValueKey('anim_${account.id}')).fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
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

}
