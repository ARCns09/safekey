import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../database/database.dart';
import 'package:flutter/services.dart';

class RecoveryCodesScreen extends ConsumerStatefulWidget {
  final Account account;

  const RecoveryCodesScreen({super.key, required this.account});

  @override
  ConsumerState<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends ConsumerState<RecoveryCodesScreen> {
  final _codeController = TextEditingController();

  Future<void> _addCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final newCode = RecoveryCodesCompanion.insert(
      accountId: widget.account.id,
      code: code,
    );

    await ref.read(accountRepositoryProvider).insertRecoveryCode(newCode);
    _codeController.clear();
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery code copied to clipboard')),
      );
    }
  }

  void _showAddCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recovery Code'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Code',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _addCode();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(accountRepositoryProvider);
    final codesStream = repo.watchRecoveryCodesForAccount(widget.account.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.issuer} Recovery Codes'),
      ),
      body: StreamBuilder<List<RecoveryCode>>(
        stream: codesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final codes = snapshot.data ?? [];
          if (codes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No Recovery Codes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Store one-time recovery codes here. They are securely encrypted on your device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final code = codes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    code.code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: code.isUsed ? TextDecoration.lineThrough : null,
                      color: code.isUsed ? Colors.grey : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: code.isUsed ? null : () => _copyToClipboard(code.code),
                        tooltip: 'Copy Code',
                      ),
                      Checkbox(
                        value: code.isUsed,
                        onChanged: (val) {
                          if (val != null) {
                            repo.updateRecoveryCode(code.copyWith(isUsed: val));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Code?'),
                              content: const Text('Are you sure you want to delete this recovery code?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            repo.deleteRecoveryCode(code);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCodeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Code'),
      ),
    );
  }
}
