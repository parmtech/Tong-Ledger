import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/sqlcipher_journal_stage.dart';
import 'package:tong_ledger/storage/sqlcipher_migration_candidate.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final key = List<int>.filled(32, 91); // Fictional fixture key only.

  testWidgets('normalized append persists separate rows and protects history',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('normalized-journal-test-');
    SqlCipherJournalStage? stage;
    Database? raw;
    try {
      final opened = await SqlCipherJournalStage.create(
        stagingRoot: root, key: key,
        initial: BalancedJournal(accounts: const {
          'cash': JournalAccount(id: 'cash', type: JournalAccountType.cashAsset),
          'expense': JournalAccount(id: 'expense', type: JournalAccountType.expense),
        }, batches: []),
      );
      stage = opened;
      final batch = JournalBatch(id: 'test-transaction', at: DateTime.utc(2026, 1, 1),
        postings: const [
          JournalPosting(accountId: 'expense', side: JournalSide.debit, amountCents: 50),
          JournalPosting(accountId: 'cash', side: JournalSide.credit, amountCents: 50),
        ]);
      await opened.append(expectedRevision: 0, batch: batch);
      final file = opened.file;
      await opened.close();
      stage = null;

      final db = await openDatabase(file.path, password: base64Encode(key),
          singleInstance: false);
      raw = db;
      expect(await db.getVersion(), 2);
      expect(await db.query('journal_accounts'), hasLength(2));
      expect(await db.query('journal_batches'), hasLength(1));
      expect(await db.query('journal_postings'), hasLength(2));
      await expectLater(db.delete('journal_postings'),
          throwsA(isA<DatabaseException>()));
      await expectLater(db.update('journal_batches', {'id': 'changed'}),
          throwsA(isA<DatabaseException>()));
      expect(await db.query('journal_postings'), hasLength(2));
      await db.close();
      raw = null;

      final reopened = await SqlCipherJournalStage.reopen(file: file, key: key);
      stage = reopened;
      final state = await reopened.read();
      expect(state.number, 1);
      expect(state.journal.batches.single.id, 'test-transaction');
      expect(state.journal.balances, {'cash': -50, 'expense': 50});
    } finally {
      try {
        await stage?.close();
        await raw?.close();
      } finally {
        await root.delete(recursive: true);
      }
    }
  });

  testWidgets('large Unicode legacy metadata is preserved in encrypted chunks',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('snapshot-chunks-test-');
    Database? raw;
    try {
      final book = FinanceBook(assets: [
        AssetRecord(id: 'fixture-asset', name: List.filled(70000, 'é').join(),
          valuationCents: 100, asOf: DateTime.utc(2026, 1, 1)),
      ]);
      final snapshot = FinanceBookCodec.encode(book);
      final file = await SqlCipherMigrationCandidate.create(
        stagingRoot: root, sourceSnapshot: snapshot, key: key,
      );
      final db = await openDatabase(file.path, password: base64Encode(key),
          singleInstance: false);
      raw = db;
      expect((await db.query('legacy_snapshot')).length, greaterThan(1));
      await expectLater(db.delete('legacy_snapshot'),
          throwsA(isA<DatabaseException>()));
      await db.close();
      raw = null;
      await SqlCipherMigrationCandidate.verify(
        file: file, sourceSnapshot: snapshot, key: key,
      );
    } finally {
      try {
        await raw?.close();
      } finally {
        await root.delete(recursive: true);
      }
    }
  });
}
