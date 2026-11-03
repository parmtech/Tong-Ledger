import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/finance_models.dart';
import 'encrypted_document.dart';
import 'finance_book_codec.dart';
import 'backup_integrity_validator.dart';
import 'finance_store.dart';
import 'vault_key_access.dart';

class SecureStorageFailure implements Exception {
  const SecureStorageFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Android-first encrypted snapshot with staged, fail-closed recovery.
/// The full transactional database remains a separate P0 milestone.
class SecureFinanceStore implements RecoverableFinanceStore {
  SecureFinanceStore({
    FlutterSecureStorage? secureStorage,
    VaultKeyAccess? keyAccess,
    Future<Directory> Function()? supportDirectory,
    EncryptedDocument? cipher,
  }) : _keys = keyAccess ??
           AndroidVaultKeyAccess(secureStorage ??
             const FlutterSecureStorage(
               aOptions: AndroidOptions(encryptedSharedPreferences: true),
             )),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _cipher = cipher ?? EncryptedDocument();

  final VaultKeyAccess _keys;
  final Future<Directory> Function() _supportDirectory;
  final EncryptedDocument _cipher;
  static const _primarySlot = 'tong_ledger_snapshot_key_v1';
  static const _recoverySlot = 'tong_ledger_recovery_key_v1';
  static const _filename = 'tong_ledger_private_v1.enc';
  bool _working = false;

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    if (_working) {
      throw const SecureStorageFailure('Vault operation already in progress.');
    }
    _working = true;
    try {
      return await operation();
    } finally {
      _working = false;
    }
  }

  Future<File> _file() async {
    final directory = await _supportDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_filename');
  }

  File _candidate(File file) => File('${file.path}.recovery.pending');
  File _marker(File file) => File('${file.path}.recovery-in-progress');

  List<int> _newKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  List<int> _decodeKey(String encoded) {
    try {
      final key = base64Decode(encoded);
      if (key.length == 32) return key;
    } catch (_) {
      // Never reset or silently overwrite an unreadable vault.
    }
    throw const SecureStorageFailure('Invalid vault key.');
  }

  Future<List<int>> _primaryKey({required bool existingFile}) async {
    final saved = await _keys.read(_primarySlot);
    if (saved != null) return _decodeKey(saved);
    if (existingFile) {
      throw const SecureStorageFailure(
        'Encrypted records exist but the device key is missing. '
        'No records have been overwritten.',
      );
    }
    final key = _newKey();
    await _keys.write(_primarySlot, base64Encode(key));
    return key;
  }

  Future<FinanceBook> _decrypt(File file, List<int> key) async {
    return FinanceBookCodec.decode(
      await _cipher.decrypt(await file.readAsString(), key),
    );
  }

  Future<FinanceBook> _loadInternal() async {
    final file = await _file();
    final marker = _marker(file);
    if (!await file.exists()) {
      if (await marker.exists() || await _candidate(file).exists()) {
        throw const SecureStorageFailure(
          'Interrupted recovery detected. No empty vault was created. '
          'Recover from your password-protected backup.',
        );
      }
      return FinanceBook();
    }

    Object? primaryError;
    try {
      final primary = await _primaryKey(existingFile: true);
      final book = await _decrypt(file, primary);
      // A valid primary key authenticates the active vault. If recovery
      // was interrupted before file activation, retain the old vault and
      // discard only the nonactive candidate / staging marker. If activation
      // already succeeded, this finalises a completed recovery instead.
      if (await marker.exists()) {
        await _keys.delete(_recoverySlot);
        if (await _candidate(file).exists()) {
          await _candidate(file).delete();
        }
        await marker.delete();
      }
      return book;
    } catch (error) {
      primaryError = error;
    }

    // If the vault was activated but key promotion was interrupted, the
    // secondary OS-protected key can decrypt it and repair the primary slot.
    try {
      final staged = await _keys.read(_recoverySlot);
      if (staged != null && await marker.exists()) {
        final book = await _decrypt(file, _decodeKey(staged));
        await _keys.write(_primarySlot, staged);
        await _keys.delete(_recoverySlot);
        if (await marker.exists()) await marker.delete();
        return book;
      }
    } catch (_) {
      // Never reset or truncate the vault on an authentication failure.
    }
    throw SecureStorageFailure(
      'Encrypted vault could not be unlocked. No data was reset. '
      'Recover from a separate encrypted backup. '
      '(Key verification: ${primaryError.runtimeType})',
    );
  }

  @override
  Future<FinanceBook> load() => _exclusive(_loadInternal);

  @override
  Future<void> save(FinanceBook book) => _exclusive(() async {
    final json = FinanceBookCodec.encode(book);
    FinanceBookCodec.decode(json);
    final file = await _file();
    if (await _marker(file).exists()) {
      throw const SecureStorageFailure(
        'Recovery needs attention before normal saving can continue.',
      );
    }
    final key = await _primaryKey(existingFile: await file.exists());
    final envelope = await _cipher.encrypt(json, key);
    final temp = File('${file.path}.pending');
    try {
      await temp.writeAsString(envelope, flush: true);
      await temp.rename(file.path);
    } catch (_) {
      throw const SecureStorageFailure(
        'Encrypted save failed. Existing vault was not intentionally deleted.',
      );
    }
  });

  /// Only after the backup's passphrase, AEAD tag, schema and ledger pass
  /// validation. Preserve original ciphertext; never silently wipe it.
  @override
  Future<void> restoreVerifiedBackup(FinanceBook restored) =>
      _exclusive(() async {
    final json = FinanceBookCodec.encode(restored);
    FinanceBookCodec.decode(json);
    BackupIntegrityValidator.validate(restored);
    final file = await _file();
    final candidate = _candidate(file);
    final marker = _marker(file);
    final newKey = _newKey();
    final encodedKey = base64Encode(newKey);

    // Prepare and authenticate the replacement while old data remains active.
    final encrypted = await _cipher.encrypt(json, newKey);
    await candidate.writeAsString(encrypted, flush: true);
    final verified = await _decrypt(candidate, newKey);
    if (FinanceBookCodec.encode(verified) != json) {
      throw const SecureStorageFailure('Recovery candidate verification failed.');
    }

    if (await file.exists()) {
      final random = Random.secure();
      final suffix = List<int>.generate(12, (_) => random.nextInt(256))
          .map((v) => v.toRadixString(16).padLeft(2, '0')).join();
      final preserved = File('${file.path}.preserved-$suffix.enc');
      await file.copy(preserved.path);
      if (await preserved.length() != await file.length()) {
        throw const SecureStorageFailure(
          'Original ciphertext could not be preserved. Restore aborted.',
        );
      }
    }

    // Both key writes stay in Android-protected storage; the file contains
    // ciphertext only. The marker blocks accidental empty-vault creation.
    await _keys.write(_recoverySlot, encodedKey);
    await marker.writeAsString('tong-ledger-recovery-v1', flush: true);
    try {
      await candidate.rename(file.path);
      await _keys.write(_primarySlot, encodedKey);
      await _decrypt(file, newKey);
      await _keys.delete(_recoverySlot);
      if (await marker.exists()) await marker.delete();
    } catch (_) {
      throw const SecureStorageFailure(
        'Recovery interrupted. Encrypted recovery evidence was preserved; '
        'restart or retry from the same backup. Do not clear app storage.',
      );
    }
  });
}
