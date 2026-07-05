import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:base32/base32.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../database/database.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  String _issuer = '';
  String _accountName = '';
  String _secret = '';
  String _tags = '';
  String _algorithm = 'SHA1';
  int _digits = 6;

  void _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final cleanSecret = _secret.replaceAll(' ', '').toUpperCase();
      
      final newAccount = AccountsCompanion.insert(
        issuer: _issuer,
        accountName: _accountName,
        secret: cleanSecret,
        tags: drift.Value(_tags),
        algorithm: drift.Value(_algorithm),
        digits: drift.Value(_digits),
      );

      await ref.read(accountRepositoryProvider).insertAccount(newAccount);
      
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAccount,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Issuer (e.g. Google)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _issuer = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Account Name (e.g. user@gmail.com)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _accountName = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final clean = val.replaceAll(' ', '').toUpperCase();
                  try {
                    base32.decode(clean);
                  } catch (e) {
                    return 'Invalid Base32 Secret';
                  }
                  return null;
                },
                onSaved: (val) => _secret = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tags (e.g. Work, Personal, Social)',
                  border: OutlineInputBorder(),
                  hintText: 'Comma separated',
                ),
                onSaved: (val) => _tags = val ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _algorithm,
                decoration: const InputDecoration(
                  labelText: 'Algorithm',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'SHA1', child: Text('SHA-1')),
                  DropdownMenuItem(value: 'SHA256', child: Text('SHA-256')),
                  DropdownMenuItem(value: 'SHA512', child: Text('SHA-512')),
                ],
                onChanged: (val) {
                  setState(() {
                    _algorithm = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _digits,
                decoration: const InputDecoration(
                  labelText: 'Digits',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 Digits')),
                  DropdownMenuItem(value: 8, child: Text('8 Digits')),
                ],
                onChanged: (val) {
                  setState(() {
                    _digits = val!;
                  });
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveAccount,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Account', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
