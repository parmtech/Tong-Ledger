import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/domain/journal_reversal.dart';

void main() {
  final at = DateTime.utc(2026, 11, 1);
  final later = DateTime.utc(2026, 11, 2);
  final original = JournalBatch(
    id: 'transaction/t1',
    at: at,
    category: 'Food',
    postings: const [
      JournalPosting(accountId: 'expense', side: JournalSide.debit,
        amountCents: 1234),
      JournalPosting(accountId: 'cash', side: JournalSide.credit,
        amountCents: 1234),
    ],
  );
  final journal = BalancedJournal(
    accounts: const {
      'expense': JournalAccount(id: 'expense', type: JournalAccountType.expense),
      'cash': JournalAccount(id: 'cash', type: JournalAccountType.cashAsset),
    },
    batches: [original],
  );

  test('reversal appends exact inverse without editing original', () {
    final revised = JournalReversal.append(
      journal: journal, originalId: original.id, effectiveAt: later,
    );
    expect(journal.batches, [original]);
    expect(journal.balances, {'expense': 1234, 'cash': -1234});
    expect(revised.batches.first, same(original));
    expect(revised.balances, {'expense': 0, 'cash': 0});
    final reversal = revised.batches.last;
    expect(reversal.id, 'reversal/transaction/t1');
    expect(reversal.category, 'Food');
    expect(reversal.at, later);
    expect(reversal.postings.first.side, JournalSide.credit);
    expect(reversal.postings.first.amountCents, 1234);
    expect(reversal.postings.first.currency, 'AUD');
  });

  test('duplicate reversal is rejected', () {
    final revised = JournalReversal.append(
      journal: journal, originalId: original.id, effectiveAt: later,
    );
    expect(() => JournalReversal.append(
      journal: revised, originalId: original.id, effectiveAt: later,
    ), throwsA(isA<JournalIntegrityException>()));
    expect(revised.batches.length, 2);
  });

  test('unknown, opening and reversal IDs are rejected', () {
    for (final id in ['transaction/missing', 'opening/cash', 'reversal/transaction/t1']) {
      expect(() => JournalReversal.append(
        journal: journal, originalId: id, effectiveAt: later,
      ), throwsA(isA<JournalIntegrityException>()));
    }
  });

  test('effective date cannot predate original', () {
    expect(() => JournalReversal.append(
      journal: journal, originalId: original.id,
      effectiveAt: DateTime.utc(2026, 10, 31),
    ), throwsA(isA<JournalIntegrityException>()));
  });
}
