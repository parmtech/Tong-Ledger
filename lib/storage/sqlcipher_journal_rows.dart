import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/balanced_journal.dart';
import 'journal_revision_codec.dart';
import 'journal_transaction_store.dart';

/// Row layout for the isolated encrypted database. All mutations must occur
/// inside the owning SQLite transaction. No plaintext files are created.
class SqlCipherJournalRows {
  const SqlCipherJournalRows._();

  static const _maxAccounts = 100000;
  static const _maxBatches = 100000;
  static const _maxPostings = 400000;
  static const _maxJournalBytes = 64 * 1024 * 1024;
  static const _maxSnapshotBytes = 32 * 1024 * 1024;
  static const _chunkBytes = 128 * 1024;
  static const _maxChunks = _maxSnapshotBytes ~/ _chunkBytes;

  static String validate(JournalRevision state) {
    final journal = state.journal;
    if (journal.accounts.length > _maxAccounts ||
        journal.batches.length > _maxBatches ||
        state.number > journal.batches.length ||
        journal.batches.fold<int>(0, (n, b) => n + b.postings.length) >
            _maxPostings) {
      throw const FormatException('Journal exceeds staging row limits.');
    }
    final payload = JournalRevisionCodec.encode(state);
    if (utf8.encode(payload).length > _maxJournalBytes) {
      throw const FormatException('Journal exceeds staging byte limit.');
    }
    JournalRevisionCodec.decode(payload);
    return payload;
  }

  static void validateSnapshot(String snapshot) {
    if (utf8.encode(snapshot).length > _maxSnapshotBytes) {
      throw const FormatException('Legacy snapshot exceeds staging limit.');
    }
  }

  static Future<void> initialize(
    DatabaseExecutor db, JournalRevision state, String? snapshot,
  ) async {
    await db.execute(
      'CREATE TABLE journal_revision ('
      'id INTEGER PRIMARY KEY CHECK(id = 1), '
      'revision INTEGER NOT NULL CHECK(revision >= 0), '
      'initial_batches INTEGER NOT NULL CHECK(initial_batches >= 0))',
    );
    await db.execute(
      'CREATE TABLE journal_accounts ('
      'id TEXT PRIMARY KEY NOT NULL, '
      'ordinal INTEGER NOT NULL UNIQUE CHECK(ordinal >= 0), '
      "type TEXT NOT NULL, currency TEXT NOT NULL CHECK(currency = 'AUD'))",
    );
    await db.execute(
      'CREATE TABLE journal_batches ('
      'ordinal INTEGER PRIMARY KEY CHECK(ordinal >= 0), '
      'id TEXT NOT NULL UNIQUE, at TEXT NOT NULL, category TEXT)',
    );
    await db.execute(
      'CREATE TABLE journal_postings ('
      'batch_ordinal INTEGER NOT NULL REFERENCES journal_batches(ordinal), '
      'ordinal INTEGER NOT NULL CHECK(ordinal BETWEEN 0 AND 15), '
      'account_id TEXT NOT NULL REFERENCES journal_accounts(id), '
      "side TEXT NOT NULL CHECK(side IN ('debit', 'credit')), "
      'amount_cents INTEGER NOT NULL CHECK(amount_cents BETWEEN 1 AND 100000000000000), '
      "currency TEXT NOT NULL CHECK(currency = 'AUD'), "
      'PRIMARY KEY(batch_ordinal, ordinal))',
    );
    await db.execute(
      'CREATE INDEX journal_postings_account '
      'ON journal_postings(account_id, batch_ordinal)',
    );
    await db.execute('CREATE INDEX journal_batches_date ON journal_batches(at)');
    await db.execute(
      'CREATE TABLE legacy_snapshot ('
      'ordinal INTEGER PRIMARY KEY CHECK(ordinal >= 0), '
      'payload BLOB NOT NULL CHECK(length(payload) BETWEEN 1 AND 131072))',
    );
    // Guard against accidental UPDATE/DELETE by future application code.
    // These are SQL constraints, not protection from a malicious key holder.
    for (final table in [
      'journal_accounts', 'journal_batches', 'journal_postings', 'legacy_snapshot',
    ]) {
      for (final operation in ['UPDATE', 'DELETE']) {
        await db.execute(
          'CREATE TRIGGER guard_${table}_${operation.toLowerCase()} '
          'BEFORE $operation ON $table '
          "BEGIN SELECT RAISE(ABORT, 'immutable journal row'); END",
        );
      }
    }
    await db.execute(
      'CREATE TRIGGER guard_journal_origin '
      'BEFORE UPDATE OF id, initial_batches ON journal_revision '
      "BEGIN SELECT RAISE(ABORT, 'immutable journal origin'); END",
    );
    await db.insert('journal_revision', {
      'id': 1, 'revision': 0, 'initial_batches': state.journal.batches.length,
    });
    final accounts = db.batch();
    var ordinal = 0;
    for (final account in state.journal.accounts.values) {
      accounts.insert('journal_accounts', {
        'id': account.id, 'ordinal': ordinal++, 'type': account.type.name,
        'currency': account.currency,
      });
    }
    await accounts.commit(noResult: true);
    // Bounded batch sizes keep the native bridge from accumulating the entire
    // history in a single platform-channel request.
    for (var i = 0; i < state.journal.batches.length; i += 256) {
      final end = i + 256 < state.journal.batches.length
          ? i + 256 : state.journal.batches.length;
      final rows = db.batch();
      for (var j = i; j < end; j++) {
        _queueBatch(rows, j, state.journal.batches[j]);
      }
      await rows.commit(noResult: true);
    }
    if (snapshot != null) {
      final bytes = utf8.encode(snapshot);
      final chunks = db.batch();
      for (var i = 0; i < bytes.length; i += _chunkBytes) {
        final end = i + _chunkBytes < bytes.length ? i + _chunkBytes : bytes.length;
        chunks.insert('legacy_snapshot', {
          'ordinal': i ~/ _chunkBytes,
          'payload': Uint8List.fromList(bytes.sublist(i, end)),
        });
      }
      await chunks.commit(noResult: true);
    }
  }

  static void _queueBatch(Batch rows, int ordinal, JournalBatch batch) {
    rows.insert('journal_batches', {
      'ordinal': ordinal, 'id': batch.id,
      'at': batch.at.toUtc().toIso8601String(), 'category': batch.category,
    });
    for (var i = 0; i < batch.postings.length; i++) {
      final posting = batch.postings[i];
      rows.insert('journal_postings', {
        'batch_ordinal': ordinal, 'ordinal': i,
        'account_id': posting.accountId, 'side': posting.side.name,
        'amount_cents': posting.amountCents, 'currency': posting.currency,
      });
    }
  }

  static Future<void> insertBatch(
    DatabaseExecutor db, int ordinal, JournalBatch batch,
  ) async {
    final rows = db.batch();
    _queueBatch(rows, ordinal, batch);
    await rows.commit(noResult: true);
  }

  static Future<JournalRevision> read(DatabaseExecutor db) async {
    final stateRows = await db.query('journal_revision', limit: 2);
    if (stateRows.length != 1 || stateRows.single['id'] != 1) {
      throw const FormatException('Invalid journal revision row.');
    }
    final revision = stateRows.single['revision'];
    final initial = stateRows.single['initial_batches'];
    if (revision is! int || initial is! int ||
        revision < 0 || initial < 0 ||
        revision > _maxBatches || initial > _maxBatches) {
      throw const FormatException('Invalid journal revision counters.');
    }
    final accounts = await db.query(
      'journal_accounts', orderBy: 'ordinal', limit: _maxAccounts + 1,
    );
    final batches = await db.query(
      'journal_batches', orderBy: 'ordinal', limit: _maxBatches + 1,
    );
    final postings = await db.query(
      'journal_postings', orderBy: 'batch_ordinal, ordinal',
      limit: _maxPostings + 1,
    );
    if (accounts.length > _maxAccounts || batches.length > _maxBatches ||
        postings.length > _maxPostings || batches.length != initial + revision) {
      throw const FormatException('Journal row counts do not match revision.');
    }
    final canonicalAccounts = <Map<String, Object?>>[];
    for (final row in accounts) {
      if (row['ordinal'] != canonicalAccounts.length) {
        throw const FormatException('Noncontiguous journal account rows.');
      }
      canonicalAccounts.add({
        'id': row['id'], 'type': row['type'], 'currency': row['currency'],
      });
    }
    final byBatch = List.generate(batches.length, (_) => <Map<String, Object?>>[]);
    for (final row in postings) {
      final batchOrdinal = row['batch_ordinal'];
      if (batchOrdinal is! int || batchOrdinal < 0 ||
          batchOrdinal >= batches.length ||
          row['ordinal'] != byBatch[batchOrdinal].length) {
        throw const FormatException('Noncontiguous journal posting rows.');
      }
      byBatch[batchOrdinal].add({
        'accountId': row['account_id'], 'side': row['side'],
        'amountCents': row['amount_cents'], 'currency': row['currency'],
      });
    }
    final canonicalBatches = <Map<String, Object?>>[];
    for (final row in batches) {
      final i = canonicalBatches.length;
      if (row['ordinal'] != i) {
        throw const FormatException('Noncontiguous journal batch rows.');
      }
      canonicalBatches.add({
        'id': row['id'], 'at': row['at'], 'category': row['category'],
        'postings': byBatch[i],
      });
    }
    final payload = jsonEncode({
      'schema': 1, 'revision': revision,
      'accounts': canonicalAccounts, 'batches': canonicalBatches,
    });
    if (utf8.encode(payload).length > _maxJournalBytes) {
      throw const FormatException('Journal exceeds staging byte limit.');
    }
    // The domain codec independently verifies currencies, balanced postings,
    // duplicate IDs, account references and canonical timestamps.
    return JournalRevisionCodec.decode(payload);
  }

  static Future<String?> readSnapshot(DatabaseExecutor db) async {
    final rows = await db.query(
      'legacy_snapshot', orderBy: 'ordinal', limit: _maxChunks + 1,
    );
    if (rows.isEmpty) return null;
    if (rows.length > _maxChunks) {
      throw const FormatException('Too many legacy snapshot chunks.');
    }
    final bytes = BytesBuilder(copy: false);
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final payload = row['payload'];
      if (row['ordinal'] != i || payload is! Uint8List ||
          payload.isEmpty || payload.length > _chunkBytes ||
          (i < rows.length - 1 && payload.length != _chunkBytes)) {
        throw const FormatException('Invalid legacy snapshot chunk.');
      }
      bytes.add(payload);
    }
    if (bytes.length > _maxSnapshotBytes) {
      throw const FormatException('Legacy snapshot exceeds staging limit.');
    }
    return utf8.decode(bytes.takeBytes());
  }
}
