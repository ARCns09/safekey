import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:otpauth_migration/otpauth_migration.dart';
import '../../database/database.dart';

class ExportScreen extends StatefulWidget {
  final List<Account> accounts;

  const ExportScreen({super.key, required this.accounts});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late List<String> _qrPayloads;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _generatePayloads();
  }

  void _generatePayloads() {
    _qrPayloads = [];
    if (widget.accounts.isEmpty) return;

    // Chunk the accounts to avoid QR codes becoming too dense to scan
    const int chunkSize = 10;
    final chunks = <List<Account>>[];
    
    for (var i = 0; i < widget.accounts.length; i += chunkSize) {
      chunks.add(widget.accounts.sublist(
          i, i + chunkSize > widget.accounts.length ? widget.accounts.length : i + chunkSize));
    }

    final migration = OtpAuthMigration();

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final chunkUris = chunk.map((a) {
        final name = Uri.encodeComponent(a.accountName);
        final issuer = Uri.encodeComponent(a.issuer);
        return "otpauth://totp/$issuer:$name?secret=${a.secret}&issuer=$issuer&algorithm=${a.algorithm}&digits=${a.digits}&period=${a.period}";
      }).toList();

      final payload = migration.encode(
        chunkUris,
        version: 1,
        batchSize: chunks.length,
        batchIndex: i,
        batchId: DateTime.now().millisecondsSinceEpoch % 100000,
      );
      _qrPayloads.add(payload);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Accounts'),
      ),
      body: _qrPayloads.isEmpty
          ? const Center(child: Text('No accounts to export.'))
          : Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Scan these QR codes with another compatible authenticator app to import your accounts.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentPage = idx;
                      });
                    },
                    itemCount: _qrPayloads.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: QrImageView(
                            data: _qrPayloads[index],
                            version: QrVersions.auto,
                            size: 280.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'QR ${_currentPage + 1} of ${_qrPayloads.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentPage > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _currentPage < _qrPayloads.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      // reverse the icon placement
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
    );
  }
}
