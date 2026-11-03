import 'finance_models.dart';

/// Fictional showcase data only. Real user data must not be entered until
/// encrypted persistent storage and appropriate privacy controls are complete.
FinanceBook createDemoBook() {
  return FinanceBook(
    institutions: [
      const Institution(id: 'cba', name: 'Commonwealth Bank'),
    ],
    accounts: [
      const CashAccount(
        id: 'salary', name: 'Salary Account', openingCents: 350000,
        institutionId: 'cba',
      ),
      const CashAccount(
        id: 'savings', name: 'Savings Account', openingCents: 550000,
        institutionId: 'cba', kind: AccountKind.savings,
      ),
      const CashAccount(
        id: 'expenses', name: 'Household Expenses', openingCents: 90000,
        institutionId: 'cba',
      ),
    ],
    cards: [
      const CreditCardAccount(
        id: 'visa', name: 'Visa Credit Card', limitCents: 800000,
        openingOwedCents: 230000, institutionId: 'cba',
      ),
    ],
    loans: [
      const LoanAccount(
        id: 'car', name: 'Car Loan', lenderName: 'Private Car Finance',
        openingOutstandingCents: 1500000, kind: 'car',
        instalmentCents: 60000,
      ),
    ],
    incomeSources: [
      const IncomeSource(
        id: 'job', name: 'Salary', expectedCents: 250000,
        cadence: 'fortnightly', destinationAccountId: 'salary',
      ),
    ],
    assets: [
      AssetRecord(
        id: 'vehicle', name: 'Vehicle (example)', valuationCents: 2200000,
        asOf: DateTime.utc(2026, 11, 1),
      ),
    ],
    entries: [
      LedgerEntry(
        id: 'groceries-demo', type: LedgerType.cashExpense,
        amountCents: 7500, sourceAccountId: 'expenses',
        category: 'Groceries', at: DateTime.utc(2026, 11, 2),
      ),
    ],
  );
}
