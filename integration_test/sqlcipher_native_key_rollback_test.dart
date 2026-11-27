import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/storage/journal_key_manager.dart';
import 'package:tong_ledger/storage/sqlcipher_journal_stage.dart';
import 'package:tong_ledger/storage/vault_key_access.dart';

/// Real platform-backed storage, isolated from all application key slots.
class _NamespacedKeys implements VaultKeyAccess {
  _NamespacedKeys(this.prefix);
  final String prefix;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _slot(String slot) => '$prefix/$slot';

  @override
  Future<String?> read(String slot) => _storage.read(key: _slot(slot));

  @override
  Future<void> write(String slot, String value) =>
      _storage.write(key: _slot(slot), value: value);

  @override
  Future<void> delete(String slot) => _storage.delete(key: _slot(slot));
}

BalancedJournal _emptyJournal() => BalancedJournal(
  accounts: const {
    'cash': JournalAccount(id: 'cash', type: JournalAccountType.cashAsset),
    'expense': JournalAccount(id: 'expense', type: JournalAccountType.expense),
  },
  batches: [],
);

JournalBatch _batch(String id) => JournalBatch(
  id: id,
  at: DateTime.utc(2026, 11, 1),
  postings: const [
    JournalPosting(
      accountId: 'expense', side: JournalSide.debit, amountCents: 100,
    ),
    JournalPosting(
      accountId: 'cash', side: JournalSide.credit, amountCents: 100,
    ),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native secure-storage key reopens encrypted journal after close',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('native-key-test-');
    final prefix = 'tong-ledger-integration/${root.path}';
    final keys = _NamespacedKeys(prefix);
    SqlCipherJournalStage? opened;
    try {
      final key = await JournalKeyManager(keys).acquire(existingEvidence: false);
      final stage = await SqlCipherJournalStage.create(
        stagingRoot: root, initial: _emptyJournal(), key: key,
      );
      opened = stage;
      await stage.append(expectedRevision: 0, batch: _batch('first'));
      final file = stage.file;
      await stage.close();
      opened = null;

      // A new adapter and manager must retrieve the same device-backed key.
      final freshKeys = _NamespacedKeys(prefix);
      final persisted = await JournalKeyManager(freshKeys)
          .acquire(existingEvidence: true);
      expect(persisted, orderedEquals(key));
      final reopened = await SqlCipherJournalStage.reopen(
        file: file, key: persisted,
      );
      opened = reopened;
      expect((await reopened.read()).journal.batches.single.id, 'first');
      await reopened.close();
      opened = null;

      await freshKeys.delete(JournalKeyManager.slot);
      await expectLater(
        JournalKeyManager(freshKeys).acquire(existingEvidence: true),
        throwsA(isA<JournalKeyFailure>()),
      );
      expect(await file.exists(), isTrue);
      expect(await freshKeys.read(JournalKeyManager.slot), isNull);
    } finally {
      try {
        await opened?.close();
        await keys.delete(JournalKeyManager.slot);
      } finally {
        await root.delete(recursive: true);
      }
    }
  });

  testWidgets('native SQLite abort rolls back journal revision and payload',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('native-rollback-test-');
    final key = List<int>.filled(32, 63); // Test-only, never a production key.
    SqlCipherJournalStage? opened;
    Database? injector;
    try {
      final initial = await SqlCipherJournalStage.create(
        stagingRoot: root, initial: _emptyJournal(), key: key,
      );
      opened = initial;
      await initial.append(expectedRevision: 0, batch: _batch('committed'));
      final file = initial.file;
      await initial.close();
      opened = null;

      // Abort a real native write after the row update has been attempted.
      // This deliberately modifies only the disposable integration fixture.
      final db = await openDatabase(
        file.path, password: base64Encode(key), singleInstance: false,
      );
      injector = db;
      await db.execute(
        "CREATE TRIGGER reject_test_write AFTER UPDATE ON journal_revision "
        "BEGIN SELECT RAISE(ABORT, 'injected native failure'); END",
      );
      await db.close();
      injector = null;

      final stage = await SqlCipherJournalStage.reopen(file: file, key: key);
      opened = stage;
      await expectLater(
        stage.append(expectedRevision: 1, batch: _batch('rejected')),
        throwsA(isA<DatabaseException>()),
      );
      await stage.close();
      opened = null;

      final after = await SqlCipherJournalStage.reopen(file: file, key: key);
      opened = after;
      final state = await after.read();
      expect(state.number, 1);
      expect(state.journal.batches.single.id, 'committed');
      expect(state.journal.balances, {'cash': -100, 'expense': 100});
    } finally {
      try {
        await opened?.close();
        await injector?.close();
      } finally {
        await root.delete(recursive: true);
      }
    }
  });
}
