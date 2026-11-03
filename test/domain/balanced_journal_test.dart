import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/domain/ledger_engine.dart';

void main() {
  DateTime at() => DateTime.utc(2026, 11, 4);

  test('all seven legacy transaction types project to balanced postings', () {
    final book = FinanceBook(
      accounts: [
        const CashAccount(id: 'salary', name: 'Salary', openingCents: 100000),
        const CashAccount(id: 'bills', name: 'Bills', openingCents: 10000),
      ],
      cards: [
        const CreditCardAccount(
          id: 'visa', name: 'Visa', openingOwedCents: 230000,
          limitCents: 800000),
      ],
      loans: [
        const LoanAccount(id: 'car', name: 'Car', lenderName: 'Private',
          openingOutstandingCents: 1500000),
      ],
      incomeSources: [
        const IncomeSource(id: 'work', name: 'Employer',
          expectedCents: 50000, cadence: 'weekly',
          destinationAccountId: 'salary'),
      ],
      entries: [
        LedgerEntry(id: 'income', type: LedgerType.income, amountCents: 50000,
          destinationAccountId: 'salary', at: at()),
        LedgerEntry(id: 'spend', type: LedgerType.cashExpense, amountCents: 7500,
          sourceAccountId: 'bills', at: at()),
        LedgerEntry(id: 'transfer', type: LedgerType.transfer,
          amountCents: 20000, sourceAccountId: 'salary',
          destinationAccountId: 'bills', at: at()),
        LedgerEntry(id: 'purchase', type: LedgerType.cardPurchase,
          amountCents: 10000, cardId: 'visa', at: at()),
        LedgerEntry(id: 'cardpay', type: LedgerType.cardPayment,
          amountCents: 10000, cardId: 'visa',
          sourceAccountId: 'salary', at: at()),
        LedgerEntry(id: 'loanpay', type: LedgerType.loanPayment,
          amountCents: 60000, interestCents: 10000, loanId: 'car',
          sourceAccountId: 'salary', at: at()),
        LedgerEntry(id: 'cardrefund', type: LedgerType.cardRefund,
          amountCents: 2000, cardId: 'visa', at: at()),
        LedgerEntry(id: 'cashrefund', type: LedgerType.cashRefund,
          amountCents: 1000, destinationAccountId: 'bills', at: at()),
      ],
    );
    final legacy = calculateLedger(book);
    final journal = BalancedJournal.fromLegacy(book);
    final projection = journal.project(book);
    expect(projection.cashAccounts, legacy.accounts);
    expect(projection.cardsOwed, legacy.cardsOwed);
    expect(projection.loansOwed, legacy.loansOutstanding);
    expect(projection.cashCents, legacy.cashCents);
    expect(projection.incomeCents, legacy.incomeCents);
    expect(projection.expenseCents, legacy.expenseCents);
    expect(projection.expenseCents, 74500);
    expect(projection.loansOwed['car'], 1450000);
    expect(projection.cardsOwed['visa'], 228000);
    expect(journal.batches.length, book.entries.length + 4);
    for (final batch in journal.batches) {
      expect(() => batch.validate(journal.accounts), returnsNormally);
    }
  });

  test('opening balances use equity, never posted income or expense', () {
    final book = FinanceBook(
      accounts: [
        const CashAccount(id: 'a', name: 'Cash', openingCents: 40000),
        const CashAccount(id: 'overdraft', name: 'Overdraft',
          openingCents: -3000),
      ],
      cards: [const CreditCardAccount(id: 'card', name: 'Visa',
          limitCents: 200000, openingOwedCents: 15000)],
      loans: [const LoanAccount(id: 'loan', name: 'Car',
          lenderName: 'Company', openingOutstandingCents: 200000)],
    );
    final result = BalancedJournal.fromLegacy(book).project(book);
    expect(result.cashAccounts['a'], 40000);
    expect(result.cashAccounts['overdraft'], -3000);
    expect(result.cardsOwed['card'], 15000);
    expect(result.loansOwed['loan'], 200000);
    expect(result.incomeCents, 0);
    expect(result.expenseCents, 0);
  });

  test('all legacy demo balances are identical to shadow journal', () {
    final book = createDemoBook();
    final old = calculateLedger(book);
    final next = BalancedJournal.fromLegacy(book).project(book);
    expect(next.cashAccounts, old.accounts);
    expect(next.cardsOwed, old.cardsOwed);
    expect(next.loansOwed, old.loansOutstanding);
    expect(next.incomeCents, old.incomeCents);
    expect(next.expenseCents, old.expenseCents);
  });

  test('tampered unbalanced transaction is rejected', () {
    final ledgers = {
      'asset': const JournalAccount(id: 'asset',
          type: JournalAccountType.cashAsset),
      'revenue': const JournalAccount(id: 'revenue',
          type: JournalAccountType.income),
    };
    final invalid = JournalBatch(
      id: 'bad', at: at(),
      postings: [
        const JournalPosting(accountId: 'asset',
          side: JournalSide.debit, amountCents: 200),
        const JournalPosting(accountId: 'revenue',
          side: JournalSide.credit, amountCents: 199),
      ],
    );
    expect(() => BalancedJournal(accounts: ledgers, batches: [invalid]),
        throwsA(isA<JournalIntegrityException>()));
  });

  test('wrong currency or missing ledger rejects a journal batch', () {
    final ledgers = {
      'asset': const JournalAccount(id: 'asset',
          type: JournalAccountType.cashAsset),
      'revenue': const JournalAccount(id: 'revenue',
          type: JournalAccountType.income),
    };
    final mismatch = JournalBatch(id: 'currency', at: at(), postings: [
      const JournalPosting(accountId: 'asset',
          side: JournalSide.debit, amountCents: 10, currency: 'JPY'),
      const JournalPosting(accountId: 'revenue',
          side: JournalSide.credit, amountCents: 10),
    ]);
    final missing = JournalBatch(id: 'missing', at: at(), postings: [
      const JournalPosting(accountId: 'asset',
          side: JournalSide.debit, amountCents: 10),
      const JournalPosting(accountId: 'absent',
          side: JournalSide.credit, amountCents: 10),
    ]);
    expect(() => mismatch.validate(ledgers),
      throwsA(isA<JournalIntegrityException>()));
    expect(() => missing.validate(ledgers),
      throwsA(isA<JournalIntegrityException>()));
  });

  test('principal-only and interest-only loan payments balance correctly', () {
    final book = FinanceBook(
      accounts: [const CashAccount(id: 'cash',
          name: 'Everyday', openingCents: 100000)],
      loans: [const LoanAccount(id: 'loan', name: 'Vehicle loan',
          lenderName: 'Private lender', openingOutstandingCents: 50000)],
      entries: [
        LedgerEntry(id: 'principal', type: LedgerType.loanPayment,
          amountCents: 10000, loanId: 'loan',
          sourceAccountId: 'cash', at: at()),
        LedgerEntry(id: 'interest', type: LedgerType.loanPayment,
          amountCents: 1000, interestCents: 1000, loanId: 'loan',
          sourceAccountId: 'cash', at: at()),
      ],
    );
    final projected = BalancedJournal.fromLegacy(book).project(book);
    expect(projected.loansOwed['loan'], 40000);
    expect(projected.cashAccounts['cash'], 89000);
    expect(projected.expenseCents, 1000);
  });

  test('invalid references and repeated transaction ids are rejected', () {
    final book = FinanceBook(
      accounts: [const CashAccount(id: 'a',
          name: 'Account', openingCents: 10000)],
      entries: [
        LedgerEntry(id: 'same', type: LedgerType.income,
          amountCents: 100, destinationAccountId: 'a', at: at()),
        LedgerEntry(id: 'same', type: LedgerType.income,
          amountCents: 100, destinationAccountId: 'a', at: at()),
      ],
    );
    expect(() => BalancedJournal.fromLegacy(book),
      throwsA(isA<JournalIntegrityException>()));
    book.entries.removeLast();
    book.entries.add(LedgerEntry(id: 'missing',
      type: LedgerType.transfer, amountCents: 50,
      sourceAccountId: 'a', destinationAccountId: 'not-found', at: at()));
    expect(() => BalancedJournal.fromLegacy(book),
      throwsA(isA<JournalIntegrityException>()));
  });

  test('read-only projection does not mutate the legacy source', () {
    final book = createDemoBook();
    final entries = List<LedgerEntry>.of(book.entries);
    final originals = book.accounts.map((a) => a.openingCents).toList();
    final journal = BalancedJournal.fromLegacy(book);
    expect(journal.batches, isNotEmpty);
    expect(book.entries, orderedEquals(entries));
    expect(book.accounts.map((a) => a.openingCents), orderedEquals(originals));
    expect(() => journal.batches.add(journal.batches.first),
      throwsUnsupportedError);
  });
}
