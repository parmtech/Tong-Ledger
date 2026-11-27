import 'dart:convert';
import 'dart:math';

import 'vault_key_access.dart';

class JournalKeyFailure implements Exception {
  const JournalKeyFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Key provisioning for a single staging database lifecycle. The caller must
/// serialize filesystem and key operations across processes and must report
/// all existing database/recovery evidence, including unfinished candidates.
/// Does not activate, rotate, delete or recover any production key.
class JournalKeyManager {
  JournalKeyManager(this._keys);

  final VaultKeyAccess _keys;
  static const slot = 'tong_ledger_sqlcipher_stage_key_v1';
  bool _working = false;

  List<int> _decode(String value) {
    try {
      final key = base64Decode(value);
      if (key.length == 32 && base64Encode(key) == value) {
        return List<int>.unmodifiable(key);
      }
    } catch (_) {
      // Do not expose secret values in errors.
    }
    throw const JournalKeyFailure('Invalid database key. No key replaced.');
  }

  /// An existing database can only use its existing key. Missing keys are
  /// never regenerated for an existing or interrupted database.
  Future<List<int>> acquire({required bool existingEvidence}) async {
    if (_working) {
      throw const JournalKeyFailure('Key operation already in progress.');
    }
    _working = true;
    try {
      final saved = await _keys.read(slot);
      if (saved != null) return _decode(saved);
      if (existingEvidence) {
        throw const JournalKeyFailure('Database key missing. Recovery required.');
      }
      final random = Random.secure();
      final key = List<int>.generate(32, (_) => random.nextInt(256));
      final encoded = base64Encode(key);
      await _keys.write(slot, encoded);
      final persisted = await _keys.read(slot);
      if (persisted != encoded) {
        throw const JournalKeyFailure('Database key persistence not verified.');
      }
      return _decode(encoded);
    } finally {
      _working = false;
    }
  }
}
