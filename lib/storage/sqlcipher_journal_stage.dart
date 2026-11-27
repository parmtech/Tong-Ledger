import 'dart:convert';
import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/balanced_journal.dart';
import 'backup_integrity_validator.dart';
import 'finance_book_codec.dart';
import 'journal_revision_codec.dart';
import 'journal_transaction_store.dart';

/// Experimental SQLCipher staging adapter. Never opens or replaces the legacy
/// vault. Callers must supply a separate random 32-byte key and private
/// app-owned staging directory. No activation or key lifecycle is provided.
class SqlCipherJournalStage implements JournalTransactionStore {
  SqlCipherJournalStage._(this._db, this.file);

  final Database _db;
  final File file;
  static const _table = 'journal_revision';
  static const _maxBytes = 64 * 1024 * 1024;

  static String _password(List<int> key) {
    if (key.length != 32 || key.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError('A 32-byte database key is required.');
    }
    return base64Encode(key);
  }

  static Future<void> _requireCipher(Database db) async {
    final result = await db.rawQuery('PRAGMA cipher_version');
    if (result.isEmpty || result.first.values.isEmpty ||
        result.first.values.first == null ||
        result.first.values.first.toString().trim().isEmpty) {
      throw StateError('Native SQLCipher unavailable.');
    }
  }

  static String _encode(JournalRevision state) {
    final payload = JournalRevisionCodec.encode(state);
    if (utf8.encode(payload).length > _maxBytes) {
      throw const FormatException('Journal payload exceeds staging limit.');
    }
    JournalRevisionCodec.decode(payload);
    return payload;
  }

  static Future<SqlCipherJournalStage> create({
    required Directory stagingRoot,
    required BalancedJournal initial,
    required List<int> key,
    String? legacySnapshot,
  }) async {
    final password = _password(key);
    final payload = _encode(JournalRevision(number: 0, journal: initial));
    String? canonicalSnapshot;
    if (legacySnapshot != null) {
      final book = FinanceBookCodec.decode(legacySnapshot);
      BackupIntegrityValidator.validate(book);
      canonicalSnapshot = FinanceBookCodec.encode(book);
      final projected = JournalRevisionCodec.encode(JournalRevision(
        number: 0, journal: BalancedJournal.fromLegacy(book),
      ));
      if (projected != payload) {
        throw const FormatException('Legacy snapshot differs from initial journal.');
      }
    }
    final directory = await stagingRoot.createTemp('sqlcipher-stage-');
    final file = File('${directory.path}${Platform.pathSeparator}journal.db');
    Database? db;
    try {
      final opened = await openDatabase(
        file.path, password: password, singleInstance: false,
        version: 1,
        onConfigure: _requireCipher,
        onCreate: (database, version) async {
          await database.execute(
            'CREATE TABLE $_table (id INTEGER PRIMARY KEY CHECK(id = 1), '
            'revision INTEGER NOT NULL CHECK(revision >= 0), '
            'payload TEXT NOT NULL)',
          );
          await database.insert(_table, {'id': 1, 'revision': 0, 'payload': payload});
          await database.execute(
            'CREATE TABLE legacy_snapshot (id INTEGER PRIMARY KEY CHECK(id = 1), '
            'payload TEXT NOT NULL)',
          );
          if (canonicalSnapshot != null) {
            await database.insert('legacy_snapshot', {
              'id': 1, 'payload': canonicalSnapshot,
            });
          }
        },
      );
      db = opened;
      final stage = SqlCipherJournalStage._(opened, file);
      await stage.read();
      return stage;
    } catch (_) {
      await db?.close();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  /// Reopen an existing staging file only; never initialize a missing file.
  static Future<SqlCipherJournalStage> reopen({
    required File file,
    required List<int> key,
  }) async {
    final password = _password(key);
    if (!await file.exists()) {
      throw StateError('Staging database is missing.');
    }
    final db = await openDatabase(
      file.path, password: password, singleInstance: false,
      onConfigure: _requireCipher,
    );
    try {
      if (await db.getVersion() != 1) {
        throw const FormatException('Unsupported staging database schema.');
      }
      final stage = SqlCipherJournalStage._(db, file);
      await stage.read();
      return stage;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  static Future<JournalRevision> _read(DatabaseExecutor db) async {
    final rows = await db.query(_table, limit: 2);
    if (rows.length != 1 || rows.single['id'] != 1) {
      throw const FormatException('Invalid journal state row.');
    }
    final payload = rows.single['payload'];
    if (payload is! String || utf8.encode(payload).length > _maxBytes) {
      throw const FormatException('Invalid journal payload.');
    }
    final state = JournalRevisionCodec.decode(payload);
    if (rows.single['revision'] != state.number) {
      throw const FormatException('Journal revision mismatch.');
    }
    return state;
  }

  @override
  Future<JournalRevision> read() => _read(_db);

  @override
  Future<JournalRevision> append({
    required int expectedRevision,
    required JournalBatch batch,
  }) => _db.transaction((txn) async {
    final before = await _read(txn);
    if (before.number != expectedRevision) {
      throw const JournalWriteConflict();
    }
    final after = JournalRevision(
      number: before.number + 1,
      journal: BalancedJournal(
        accounts: before.journal.accounts,
        batches: [...before.journal.batches, batch],
      ),
    );
    final changed = await txn.update(
      _table, {'revision': after.number, 'payload': _encode(after)},
      where: 'id = ? AND revision = ?', whereArgs: [1, expectedRevision],
    );
    if (changed != 1) throw const JournalWriteConflict();
    return after;
  });

  /// Immutable migration source, not the current financial state after edits.
  Future<String?> readLegacySnapshot() async {
    final rows = await _db.query('legacy_snapshot', limit: 2);
    if (rows.isEmpty) return null;
    if (rows.length != 1 || rows.single['id'] != 1) {
      throw const FormatException('Invalid legacy snapshot row.');
    }
    final payload = rows.single['payload'];
    if (payload is! String) {
      throw const FormatException('Invalid legacy snapshot payload.');
    }
    final book = FinanceBookCodec.decode(payload);
    BackupIntegrityValidator.validate(book);
    if (FinanceBookCodec.encode(book) != payload) {
      throw const FormatException('Noncanonical legacy snapshot.');
    }
    return payload;
  }

  Future<void> close() => _db.close();
}
