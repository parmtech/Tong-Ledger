import 'package:flutter/material.dart';

import '../../domain/finance_models.dart';
import '../../storage/backup_file_service.dart';
import '../../storage/finance_store.dart';
import '../../storage/passphrase_backup.dart';

/// User-initiated export/restore; never submits financial data to a server.
class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({
    super.key, this.book, required this.store, this.files,
    this.recoveryOnly = false,
  });
  final FinanceBook? book;
  final bool recoveryOnly;
  final FinanceStore store;
  final BackupFileService? files;

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  static const _gold = Color(0xFFC8AE7D);
  late final BackupFileService _files;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _files = widget.files ?? BackupFileService();
  }

  Future<String?> _askPassphrase(bool newPassword) async {
    var password = '';
    var confirmation = '';
    return showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(newPassword ? 'Choose a backup password' : 'Unlock backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(newPassword
                  ? 'Use at least 12 characters. This password cannot be recovered.'
                  : 'Enter the password that protects your backup.'),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => password = value,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Backup password', border: OutlineInputBorder()),
              ),
              if (newPassword) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => confirmation = value,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Repeat password', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (password.runes.length <
                  PassphraseBackup.minimumPassphraseLength) {
                ScaffoldMessenger.of(dialog).showSnackBar(const SnackBar(
                  content: Text('Use at least 12 password characters.')));
                return;
              }
              if (newPassword && password != confirmation) {
                ScaffoldMessenger.of(dialog).showSnackBar(const SnackBar(
                  content: Text('Passwords do not match.')));
                return;
              }
              Navigator.pop(dialog, password);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    if (_busy) return;
    final book = widget.book;
    if (widget.recoveryOnly || book == null) return;
    final password = await _askPassphrase(true);
    if (password == null || !mounted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final saved = await _files.exportBackup(book, password);
      if (!mounted) return;
      setState(() => _status = saved
          ? 'Encrypted backup saved. Store its password separately.'
          : 'Export cancelled. No changes made.');
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Export failed. No plaintext file was saved.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final password = await _askPassphrase(false);
    if (password == null || !mounted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      // Fully authenticate + validate before any vault write.
      final imported = await _files.importBackup(password);
      if (!mounted) return;
      if (imported == null) {
        setState(() => _status = 'Restore cancelled. No changes made.');
        return;
      }
      final summary =
          'This backup includes ${imported.accounts.length} accounts, '
          '${imported.cards.length} cards, '
          '${imported.loans.length} loans and '
          '${imported.entries.length} transactions. '
          '${widget.recoveryOnly ? "The locked encrypted vault will be preserved as a safety copy. Existing records will be replaced." : "It will REPLACE current records. Save a separate backup first."}';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Replace existing data?'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep current data'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Replace all records'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) {
        if (mounted) setState(() => _status = 'Restore cancelled.');
        return;
      }
      if (widget.store is RecoverableFinanceStore) {
        await (widget.store as RecoverableFinanceStore)
            .restoreVerifiedBackup(imported);
      } else if (!widget.recoveryOnly) {
        await widget.store.save(imported);
      } else {
        throw const FormatException('This store cannot recover a locked vault.');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Restore failed. Check password and file. '
            'A missing device key may prevent recovery in this beta.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & Restore')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified_user_outlined, color: _gold, size: 60),
          const SizedBox(height: 12),
          Text('Your data, under your control',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Portable, password-encrypted backup files. '
              'No automatic cloud upload or bank connection.'),
          const SizedBox(height: 18),
          if (!widget.recoveryOnly) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const ListTile(
                  leading: Icon(Icons.lock_outline, color: _gold),
                  title: Text('Export encrypted backup'),
                  subtitle: Text('Use the Android save-file picker. '
                      'Password must be at least 12 characters.'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Save .tlbackup file'),
                ),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const ListTile(
                  leading: Icon(Icons.restore_outlined, color: _gold),
                  title: Text('Restore from backup'),
                  subtitle: Text('Unlock, inspect record counts, then '
                      'explicitly confirm replacement.'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Select encrypted backup'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Beta limitation: interrupted writes, device key '
              'invalidation and cross-device restore still need testing. '
              'Preserved ciphertext does not guarantee the old key works. '
              'Use fictional data only.'),
          if (_busy) ...[
            const SizedBox(height: 15),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_status != null) ...[
            const SizedBox(height: 15),
            Text(_status!, style: const TextStyle(color: _gold)),
          ],
        ],
      ),
    ),
  );
}
