import 'dart:convert';
import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/balanced_journal.dart';
import 'backup_integrity_validator.dart';
import 'finance_book_codec.dart';
import 'journal_revision_codec.dart';
import 'journal_transaction_store.dart';
import 'sqlcipher_journal_rows.dart';

/// Isolated schema-2 migration stage. The existing application vault remains
/// authoritative. Account registration after staging and activation are not
/// supported here. Never upgrade an old experimental database in place.
class SqlCipherJournalStage implements JournalTransactionStore {
  SqlCipherJournalStage._(this._db, this.file);

  final Database _db;
  final File file;
  static const _schemaVersion = 2;

  static String _password(List<int> key) {
    if (key.length != 32 || key.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError('A 32-byte database key is required.');
    }
    return base64Encode(key);
  }

  static Future<void> _configure(Database db) async {
    final result = await db.rawQuery('PRAGMA cipher_version');
    if (result.isEmpty || result.first.values.isEmpty ||
        result.first.values.first == null ||
        result.first.values.first.toString().trim().isEmpty) {
      throw StateError('Native SQLCipher unavailable.');
    }
    await db.execute('PRAGMA foreign_keys = ON');
    final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
    if (foreignKeys.length != 1 || foreignKeys.single.values.single != 1) {
      throw StateError('Foreign-key enforcement unavailable.');
    }
    await db.execute('PRAGMA synchronous = FULL');
  }

  static Future<SqlCipherJournalStage> create({
    required Directory stagingRoot,
    required BalancedJournal initial,
    required List<int> key,
    String? legacySnapshot,
  }) async {
    final password = _password(key);
    final state = JournalRevision(number: 0, journal: initial);
    final expected = SqlCipherJournalRows.validate(state);
    String? canonicalSnapshot;
    if (legacySnapshot != null) {
      final book = FinanceBookCodec.decode(legacySnapshot);
      BackupIntegrityValidator.validate(book);
      canonicalSnapshot = FinanceBookCodec.encode(book);
      final projected = JournalRevisionCodec.encode(JournalRevision(
        number: 0, journal: BalancedJournal.fromLegacy(book),
      ));
      if (projected != expected) {
        throw const FormatException('Legacy snapshot differs from initial journal.');
      }
      SqlCipherJournalRows.validateSnapshot(canonicalSnapshot);
    }
    final directory = await stagingRoot.createTemp('sqlcipher-stage-');
    final file = File('${directory.path}${Platform.pathSeparator}journal.db');
    Database? db;
    try {
      final opened = await openDatabase(
        file.path, password: password, singleInstance: false,
        version: _schemaVersion, onConfigure: _configure,
        onCreate: (database, version) =>
            SqlCipherJournalRows.initialize(database, state, canonicalSnapshot),
      );
      db = opened;
      final stage = SqlCipherJournalStage._(opened, file);
      if (JournalRevisionCodec.encode(await stage.read()) != expected ||
          await stage.readLegacySnapshot() != canonicalSnapshot) {
        throw const FormatException('Normalized database readback mismatch.');
      }
      return stage;
    } catch (_) {
      await db?.close();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  /// Reject earlier experimental schemas; never silently replace a file.
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
      onConfigure: _configure,
    );
    try {
      if (await db.getVersion() != _schemaVersion) {
        throw const FormatException('Unsupported staging database schema.');
      }
      final stage = SqlCipherJournalStage._(db, file);
      await stage.read();
      await stage.readLegacySnapshot();
      return stage;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  @override
  Future<JournalRevision> read() =>
      _db.transaction((txn) => SqlCipherJournalRows.read(txn));

  @override
  Future<JournalRevision> append({
    required int expectedRevision,
    required JournalBatch batch,
  }) => _db.transaction((txn) async {
    final before = await SqlCipherJournalRows.read(txn);
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
    SqlCipherJournalRows.validate(after);
    // Only the new batch, its postings and the revision are written.
    // Failure of any statement rolls the entire transaction back.
    await SqlCipherJournalRows.insertBatch(
      txn, before.journal.batches.length, batch,
    );
    final changed = await txn.update(
      'journal_revision', {'revision': after.number},
      where: 'id = ? AND revision = ?', whereArgs: [1, expectedRevision],
    );
    if (changed != 1) throw const JournalWriteConflict();
    return after;
  });

  /// Historical migration evidence, not live financial state after edits.
  Future<String?> readLegacySnapshot() async {
    final payload = await _db.transaction(
      (txn) => SqlCipherJournalRows.readSnapshot(txn),
    );
    if (payload == null) return null;
    final book = FinanceBookCodec.decode(payload);
    BackupIntegrityValidator.validate(book);
    if (FinanceBookCodec.encode(book) != payload) {
      throw const FormatException('Noncanonical legacy snapshot.');
    }
    return payload;
  }

  Future<void> close() => _db.close();
}
