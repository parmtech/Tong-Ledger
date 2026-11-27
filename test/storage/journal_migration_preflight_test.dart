import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/domain/ledger_engine.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/journal_migration_preflight.dart';

void main() {
  test('same legacy records produce exact account-level migration parity', () {
    final book = createDemoBook();
    final source = FinanceBookCodec.encode(book);
    final candidate = FinanceBookCodec.encode(FinanceBookCodec.decode(source));
    final result = JournalMigrationPreflight.verify(
      sourceSnapshot: source, candidateSnapshot: candidate,
    ).project(book);
    final old = calculateLedger(book);
    expect(result.cashAccounts, old.accounts);
    expect(result.cardsOwed, old.cardsOwed);
    expect(result.loansOwed, old.loansOutstanding);
    expect(result.incomeCents, old.incomeCents);
    expect(result.expenseCents, old.expenseCents);
    expect(FinanceBookCodec.encode(book), source);
  });

  test('same total but different account balances is rejected', () {
    final original = FinanceBook(accounts: [
      const CashAccount(id: 'a', name: 'A', openingCents: 100),
      const CashAccount(id: 'b', name: 'B', openingCents: 200),
    ]);
    final altered = FinanceBook(accounts: [
      const CashAccount(id: 'a', name: 'A', openingCents: 200),
      const CashAccount(id: 'b', name: 'B', openingCents: 100),
    ]);
    expect(() => JournalMigrationPreflight.verify(
      sourceSnapshot: FinanceBookCodec.encode(original),
      candidateSnapshot: FinanceBookCodec.encode(altered),
    ), throwsFormatException);
  });

  test('metadata loss is rejected even when all balances match', () {
    final source = FinanceBookCodec.encode(createDemoBook());
    final candidate = jsonDecode(source) as Map<String, dynamic>;
    final accounts = candidate['accounts'] as List<dynamic>;
    (accounts.first as Map<String, dynamic>)['name'] = 'Changed';
    expect(() => JournalMigrationPreflight.verify(
      sourceSnapshot: source, candidateSnapshot: jsonEncode(candidate),
    ), throwsFormatException);
  });

  test('legacy snapshots without budgets remain compatible', () {
    final current = FinanceBookCodec.encode(createDemoBook());
    final old = jsonDecode(current) as Map<String, dynamic>;
    old.remove('budgets');
    final source = jsonEncode(old);
    final candidate = FinanceBookCodec.encode(FinanceBookCodec.decode(source));
    expect(() => JournalMigrationPreflight.verify(
      sourceSnapshot: source, candidateSnapshot: candidate,
    ), returnsNormally);
  });

  test('orphaned institution links block even identical candidates', () {
    final source = FinanceBookCodec.encode(FinanceBook(accounts: [
      const CashAccount(id: 'a', name: 'A', openingCents: 100,
        institutionId: 'missing'),
    ]));
    expect(() => JournalMigrationPreflight.verify(
      sourceSnapshot: source, candidateSnapshot: source,
    ), throwsFormatException);
  });
}
