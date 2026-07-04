import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../widgets/totp_account_card.dart';

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
            title: _isSearching 
              ? TextField(
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
          : const Text('SafeKey', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ],
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
              );
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
}
