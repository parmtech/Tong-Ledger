import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/storage/journal_transaction_store.dart';

void main() {
  late MemoryJournalTransactionStore store;
  final at = DateTime.utc(2026, 11, 1);

  JournalBatch batch(String id, {int credit = 500}) => JournalBatch(
    id: id,
    at: at,
    postings: [
      const JournalPosting(accountId: 'expense', side: JournalSide.debit,
        amountCents: 500),
      JournalPosting(accountId: 'cash', side: JournalSide.credit,
        amountCents: credit),
    ],
  );

  setUp(() {
    store = MemoryJournalTransactionStore(BalancedJournal(
      accounts: const {
        'expense': JournalAccount(id: 'expense', type: JournalAccountType.expense),
        'cash': JournalAccount(id: 'cash', type: JournalAccountType.cashAsset),
      },
      batches: [],
    ));
  });

  test('commits all postings together and increments revision', () async {
    final before = await store.read();
    final after = await store.append(expectedRevision: 0, batch: batch('t1'));
    expect(after.number, 1);
    expect(after.journal.balances, {'expense': 500, 'cash': -500});
    expect(before.journal.batches, isEmpty);
    expect(await store.read(), same(after));
  });

  test('unbalanced append leaves state and revision unchanged', () async {
    final before = await store.read();
    await expectLater(store.append(
      expectedRevision: 0, batch: batch('t1', credit: 499),
    ), throwsA(isA<JournalIntegrityException>()));
    expect(await store.read(), same(before));
  });

  test('stale writer cannot append over newer revision', () async {
    final after = await store.append(expectedRevision: 0, batch: batch('t1'));
    await expectLater(store.append(expectedRevision: 0, batch: batch('t2')),
      throwsA(isA<JournalWriteConflict>()));
    expect(await store.read(), same(after));
  });

  test('duplicate transaction cannot be committed again', () async {
    final after = await store.append(expectedRevision: 0, batch: batch('t1'));
    await expectLater(store.append(expectedRevision: 1, batch: batch('t1')),
      throwsA(isA<JournalIntegrityException>()));
    expect(await store.read(), same(after));
  });

  test('concurrent writers using the same revision cannot both commit', () async {
    final first = store.append(expectedRevision: 0, batch: batch('t1'));
    final second = store.append(expectedRevision: 0, batch: batch('t2'));
    await Future.wait<void>([
      first.then<void>((value) => expect(value.number, 1)),
      expectLater(second, throwsA(isA<JournalWriteConflict>())),
    ]);
    final state = await store.read();
    expect(state.number, 1);
    expect(state.journal.batches.single.id, 't1');
  });
}
