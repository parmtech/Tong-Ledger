import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/finance_models.dart';
import 'encrypted_document.dart';
import 'finance_store.dart';
import 'finance_book_codec.dart';

class SecureStorageFailure implements Exception {
  const SecureStorageFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Android-first secure local file store.
///
/// Save uses same-directory temporary file + atomic rename on Android/Linux.
/// If ciphertext is corrupt or a key is missing we throw and NEVER reset data.
class SecureFinanceStore implements FinanceStore {
  SecureFinanceStore({
    FlutterSecureStorage? secureStorage,
    Future<Directory> Function()? supportDirectory,
    EncryptedDocument? cipher,
  })  : _keys = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
        _cipher = cipher ?? EncryptedDocument();

  final FlutterSecureStorage _keys;
  final Future<Directory> Function() _supportDirectory;
  final EncryptedDocument _cipher;

  static const _keySlot = 'tong_ledger_snapshot_key_v1';
  static const _filename = 'tong_ledger_private_v1.enc';

  Future<File> _file() async {
    final directory = await _supportDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(directory.path + Platform.pathSeparator + _filename);
  }

  Future<List<int>> _getKey({required bool existingFile}) async {
    final saved = await _keys.read(key: _keySlot);
    if (saved != null) {
      final key = base64Decode(saved);
      if (key.length != 32) {
        throw const SecureStorageFailure(
          'Invalid device encryption key. Data has not been overwritten.',
        );
      }
      return key;
    }
    if (existingFile) {
      throw const SecureStorageFailure(
        'An encrypted vault exists but the device key is missing. '
        'No files were changed. Restore the original device key or a backup.',
      );
    }
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await _keys.write(key: _keySlot, value: base64Encode(key));
    return key;
  }

  @override
  Future<FinanceBook> load() async {
    final file = await _file();
    if (!await file.exists()) return FinanceBook();
    final key = await _getKey(existingFile: true);
    try {
      final envelope = await file.readAsString();
      final json = await _cipher.decrypt(envelope, key);
      return FinanceBookCodec.decode(json);
    } catch (error) {
      throw SecureStorageFailure(
        'Encrypted financial records could not be opened. '
        'No data was erased or reset. Technical detail: ' + error.toString(),
      );
    }
  }

  @override
  Future<void> save(FinanceBook book) async {
    final plaintext = FinanceBookCodec.encode(book);
    // Validate before touching the file.
    FinanceBookCodec.decode(plaintext);
    final file = await _file();
    final key = await _getKey(existingFile: await file.exists());
    final envelope = await _cipher.encrypt(plaintext, key);
    final temporary = File(file.path + '.pending');
    try {
      await temporary.writeAsString(envelope, flush: true);
      await temporary.rename(file.path);
    } catch (error) {
      throw SecureStorageFailure(
        'Encrypted save failed; old vault was not intentionally deleted: ' +
            error.toString(),
      );
    }
  }
}
