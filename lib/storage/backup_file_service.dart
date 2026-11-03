import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/finance_models.dart';
import 'passphrase_backup.dart';

/// Android Storage Access Framework file-picker boundary.
/// No plaintext finance snapshot is written to app cache or shared via intents.
class BackupFileService {
  BackupFileService({PassphraseBackup? codec})
      : _codec = codec ?? PassphraseBackup();

  final PassphraseBackup _codec;

  /// Returns false when the user cancels the OS save dialog.
  Future<bool> exportBackup(FinanceBook book, String passphrase) async {
    final encrypted = await _codec.create(book, passphrase);
    final filename = 'tong-ledger-' +
        DateTime.now().millisecondsSinceEpoch.toString() + '.tlbackup';
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: 'Save encrypted Tong Ledger backup',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['tlbackup'],
      bytes: Uint8List.fromList(utf8.encode(encrypted)),
    );
    return destination != null;
  }

  /// Returns null when the OS picker is cancelled; never modifies the vault.
  Future<FinanceBook?> importBackup(String passphrase) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tlbackup'],
      allowMultiple: false,
      // Avoid eagerly materialising untrusted large backup bytes in memory.
      withData: false,
    );
    if (selection == null || selection.files.isEmpty) return null;
    final picked = selection.files.single;
    if (picked.size > PassphraseBackup.maxBackupBytes) {
      throw const FormatException('Backup exceeds the file size limit.');
    }
    final Uint8List bytes;
    if (picked.bytes != null) {
      bytes = picked.bytes!;
    } else if (picked.path != null) {
      final file = File(picked.path!);
      if (await file.length() > PassphraseBackup.maxBackupBytes) {
        throw const FormatException('Backup exceeds the file size limit.');
      }
      bytes = await file.readAsBytes();
    } else {
      throw const FormatException('Could not read the selected backup file.');
    }
    if (bytes.length > PassphraseBackup.maxBackupBytes) {
      throw const FormatException('Backup exceeds the file size limit.');
    }
    return _codec.open(utf8.decode(bytes), passphrase);
  }
}
