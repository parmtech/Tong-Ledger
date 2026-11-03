import 'finance_models.dart';

/// Deterministic projection of transactions onto manual opening balances.
/// Not a bank connection, a payment system, or persistent storage.
class LedgerException implements Exception {
  const LedgerException(this.message);
  final String message;

  @override
  String toString() => 'LedgerException: $message';
}

class FinanceSnapshot {
  FinanceSnapshot({
    required this.accounts,
    required this.cardsOwed,
    required this.loansOutstanding,
    required this.incomeCents,
    required this.expenseCents,
    required this.assetsCents,
  });

  final Map<String, int> accounts;
  final Map<String, int> cardsOwed;
  final Map<String, int> loansOutstanding;
  final int incomeCents;
  final int expenseCents;
  final int assetsCents;

  int get cashCents => accounts.values.fold(0, (a, b) => a + b);
  int get creditCardDebtCents => cardsOwed.values.fold(0, (a, b) => a + b);
  int get loanDebtCents => loansOutstanding.values.fold(0, (a, b) => a + b);
  int get netWorthCents => cashCents + assetsCents - creditCardDebtCents - loanDebtCents;
}

FinanceSnapshot calculateLedger(FinanceBook book) {
  final accounts = {for (final a in book.accounts) a.id: a.openingCents};
  final cards = {for (final a in book.cards) a.id: a.openingOwedCents};
  final loans = {for (final a in book.loans) a.id: a.openingOutstandingCents};
  final seen = <String>{};
  var income = 0;
  var expenses = 0;

  void debit(String? id, int amount) {
    if (id == null || !accounts.containsKey(id)) {
      throw const LedgerException('Source account missing or not found.');
    }
    accounts[id] = accounts[id]! - amount;
  }

  void credit(String? id, int amount) {
    if (id == null || !accounts.containsKey(id)) {
      throw const LedgerException('Destination account missing or not found.');
    }
    accounts[id] = accounts[id]! + amount;
  }

  void increaseCard(String? id, int amount) {
    if (id == null || !cards.containsKey(id)) {
      throw const LedgerException('Card missing or not found.');
    }
    cards[id] = cards[id]! + amount;
  }

  for (final e in book.entries) {
    if (!seen.add(e.id)) throw const LedgerException('Duplicate transaction id.');
    if (e.amountCents <= 0) {
      throw const LedgerException('Transaction amount must be greater than zero.');
    }
    switch (e.type) {
      case LedgerType.income:
        credit(e.destinationAccountId, e.amountCents);
        income += e.amountCents;
      case LedgerType.cashExpense:
        debit(e.sourceAccountId, e.amountCents);
        expenses += e.amountCents;
      case LedgerType.transfer:
        if (e.sourceAccountId == e.destinationAccountId) {
          throw const LedgerException('Source and destination must differ.');
        }
        debit(e.sourceAccountId, e.amountCents);
        credit(e.destinationAccountId, e.amountCents);
      case LedgerType.cardPurchase:
        increaseCard(e.cardId, e.amountCents);
        expenses += e.amountCents;
      case LedgerType.cardPayment:
        if (e.cardId == null || !cards.containsKey(e.cardId)) {
          throw const LedgerException('Card missing or not found.');
        }
        debit(e.sourceAccountId, e.amountCents);
        cards[e.cardId!] = cards[e.cardId!]! - e.amountCents;
      case LedgerType.loanPayment:
        if (e.loanId == null || !loans.containsKey(e.loanId)) {
          throw const LedgerException('Loan missing or not found.');
        }
        if (e.interestCents < 0 || e.interestCents > e.amountCents) {
          throw const LedgerException('Interest split must be within the payment.');
        }
        final principal = e.amountCents - e.interestCents;
        if (principal > loans[e.loanId!]!) {
          throw const LedgerException('Loan principal repayment exceeds outstanding balance.');
        }
        debit(e.sourceAccountId, e.amountCents);
        loans[e.loanId!] = loans[e.loanId!]! - principal;
        expenses += e.interestCents;
      case LedgerType.cardRefund:
        increaseCard(e.cardId, -e.amountCents);
        expenses -= e.amountCents;
      case LedgerType.cashRefund:
        credit(e.destinationAccountId, e.amountCents);
        expenses -= e.amountCents;
    }
  }

  return FinanceSnapshot(
    accounts: Map.unmodifiable(accounts),
    cardsOwed: Map.unmodifiable(cards),
    loansOutstanding: Map.unmodifiable(loans),
    incomeCents: income,
    expenseCents: expenses,
    assetsCents: book.assets.fold(0, (a, b) => a + b.valuationCents),
  );
}
