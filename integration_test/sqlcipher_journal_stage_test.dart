import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/storage/journal_transaction_store.dart';
import 'package:tong_ledger/storage/sqlcipher_journal_stage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('encrypted stage persists, rejects invalid writes and wrong key',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('journal-native-test-');
    final key = List<int>.generate(32, (i) => i + 1);
    SqlCipherJournalStage? stage;
    try {
      final initial = BalancedJournal(accounts: const {
        'cash': JournalAccount(id: 'cash', type: JournalAccountType.cashAsset),
        'expense': JournalAccount(id: 'expense', type: JournalAccountType.expense),
      }, batches: []);
      final opened = await SqlCipherJournalStage.create(
        stagingRoot: root, initial: initial, key: key,
      );
      stage = opened;
      JournalBatch batch(String id, int credit) => JournalBatch(
        id: id, at: DateTime.utc(2026, 11, 1), postings: [
          const JournalPosting(accountId: 'expense', side: JournalSide.debit,
            amountCents: 100),
          JournalPosting(accountId: 'cash', side: JournalSide.credit,
            amountCents: credit),
        ],
      );
      await opened.append(expectedRevision: 0, batch: batch('test-1', 100));
      await expectLater(opened.append(expectedRevision: 1, batch: batch('bad', 99)),
        throwsA(isA<JournalIntegrityException>()));
      await expectLater(opened.append(expectedRevision: 0, batch: batch('stale', 100)),
        throwsA(isA<JournalWriteConflict>()));
      final file = opened.file;
      await opened.close();
      stage = null;
      final header = await file.openRead(0, 16).expand((chunk) => chunk).toList();
      expect(ascii.decode(header, allowInvalid: true), isNot('SQLite format 3\u0000'));
      await expectLater(
        SqlCipherJournalStage.reopen(file: file, key: List<int>.filled(32, 255)),
        throwsA(anything),
      );
      final reopened = await SqlCipherJournalStage.reopen(file: file, key: key);
      stage = reopened;
      final after = await reopened.read();
      expect(after.number, 1);
      expect(after.journal.balances, {'cash': -100, 'expense': 100});
      expect(after.journal.batches.single.id, 'test-1');
    } finally {
      await stage?.close();
      await root.delete(recursive: true);
    }
  });
}
