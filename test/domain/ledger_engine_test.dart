import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/domain/ledger_engine.dart';

void main() {
  DateTime date() => DateTime.utc(2026, 11, 3);

  test('cash transfer has no impact on aggregate cash, income or expense', () {
    final book = FinanceBook(
      accounts: [
        const CashAccount(id: 'a', name: 'A', openingCents: 100000),
        const CashAccount(id: 'b', name: 'B', openingCents: 20000),
      ],
      entries: [
        LedgerEntry(id: 't1', type: LedgerType.transfer, amountCents: 20000,
          sourceAccountId: 'a', destinationAccountId: 'b', at: date()),
      ],
    );
    final s = calculateLedger(book);
    expect(s.accounts['a'], 80000);
    expect(s.accounts['b'], 40000);
    expect(s.cashCents, 120000);
    expect(s.incomeCents, 0);
    expect(s.expenseCents, 0);
  });

  test('card purchase increases owed; payment is not a second expense', () {
    final book = FinanceBook(
      accounts: [const CashAccount(id: 'cash', name: 'Cash', openingCents: 100000)],
      cards: [const CreditCardAccount(
        id: 'card', name: 'Visa', limitCents: 800000, openingOwedCents: 230000,
      )],
      entries: [
        LedgerEntry(id: 'purchase', type: LedgerType.cardPurchase,
          cardId: 'card', amountCents: 10000, at: date(), category: 'Groceries'),
        LedgerEntry(id: 'payment', type: LedgerType.cardPayment,
          cardId: 'card', sourceAccountId: 'cash', amountCents: 10000, at: date()),
      ],
    );
    final s = calculateLedger(book);
    expect(s.cardsOwed['card'], 230000);
    expect(s.accounts['cash'], 90000);
    expect(s.expenseCents, 10000);
    expect(800000 - s.cardsOwed['card']!, 570000);
  });

  test('loan principal reduces loan; only interest is expense', () {
    final book = FinanceBook(
      accounts: [const CashAccount(id: 'a', name: 'Cash', openingCents: 100000)],
      loans: [const LoanAccount(id: 'car', name: 'Car Loan',
        lenderName: 'Private Company', openingOutstandingCents: 1500000)],
      entries: [
        LedgerEntry(id: 'repayment', type: LedgerType.loanPayment, amountCents: 60000,
          interestCents: 10000, sourceAccountId: 'a', loanId: 'car', at: date()),
      ],
    );
    final s = calculateLedger(book);
    expect(s.accounts['a'], 40000);
    expect(s.loansOutstanding['car'], 1450000);
    expect(s.expenseCents, 10000);
  });

  test('future income sources do not change actual balances', () {
    final s = calculateLedger(FinanceBook(
      accounts: [const CashAccount(id: 'a', name: 'Cash', openingCents: 10000)],
      incomeSources: [const IncomeSource(id: 'salary', name: 'Salary',
        expectedCents: 200000, cadence: 'fortnightly', destinationAccountId: 'a')],
    ));
    expect(s.accounts['a'], 10000);
    expect(s.incomeCents, 0);
  });

  test('invalid transaction references are rejected', () {
    final book = FinanceBook(entries: [
      LedgerEntry(id: 'bad', type: LedgerType.cashExpense,
        amountCents: 100, sourceAccountId: 'missing', at: date()),
    ]);
    expect(() => calculateLedger(book), throwsA(isA<LedgerException>()));
  });
  test('duplicate transaction ids are rejected', () {
    final book = FinanceBook(accounts: [
      const CashAccount(id: 'a', name: 'A', openingCents: 1000),
    ], entries: [
      LedgerEntry(id: 'same', type: LedgerType.income,
        amountCents: 100, destinationAccountId: 'a', at: date()),
      LedgerEntry(id: 'same', type: LedgerType.income,
        amountCents: 100, destinationAccountId: 'a', at: date()),
    ]);
    expect(() => calculateLedger(book), throwsA(isA<LedgerException>()));
  });
}
