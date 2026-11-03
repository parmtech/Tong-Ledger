/// Pure Dart models. These are intentionally UI- and storage-independent.
/// This initial sample operates in memory only. Do not enter real personal data.
enum AccountKind { transaction, savings, cash, offset, other }

enum LedgerType {
  income,
  cashExpense,
  transfer,
  cardPurchase,
  cardPayment,
  loanPayment,
  cardRefund,
  cashRefund,
}

class Institution {
  const Institution({required this.id, required this.name, this.kind = 'bank'});
  final String id;
  final String name;
  final String kind;
}

class CashAccount {
  const CashAccount({
    required this.id,
    required this.name,
    required this.openingCents,
    this.institutionId,
    this.kind = AccountKind.transaction,
  });
  final String id;
  final String name;
  final int openingCents;
  final String? institutionId;
  final AccountKind kind;
}

class CreditCardAccount {
  const CreditCardAccount({
    required this.id,
    required this.name,
    required this.limitCents,
    required this.openingOwedCents,
    this.institutionId,
  });
  final String id;
  final String name;
  final int limitCents;
  final int openingOwedCents;
  final String? institutionId;
}

class LoanAccount {
  const LoanAccount({
    required this.id,
    required this.name,
    required this.openingOutstandingCents,
    required this.lenderName,
    this.institutionId,
    this.kind = 'personal',
    this.instalmentCents,
  });
  final String id;
  final String name;
  final String lenderName;
  final int openingOutstandingCents;
  final String? institutionId;
  final String kind;
  final int? instalmentCents;
}

class AssetRecord {
  const AssetRecord({
    required this.id,
    required this.name,
    required this.valuationCents,
    required this.asOf,
  });
  final String id;
  final String name;
  final int valuationCents;
  final DateTime asOf;
}

class IncomeSource {
  const IncomeSource({
    required this.id,
    required this.name,
    required this.expectedCents,
    required this.cadence,
    this.destinationAccountId,
  });
  final String id;
  final String name;
  final int expectedCents;
  final String cadence;
  final String? destinationAccountId;
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.at,
    this.sourceAccountId,
    this.destinationAccountId,
    this.cardId,
    this.loanId,
    this.interestCents = 0,
    this.category,
  });
  final String id;
  final LedgerType type;
  final int amountCents;
  final DateTime at;
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String? cardId;
  final String? loanId;
  final int interestCents;
  final String? category;
}

class FinanceBook {
  FinanceBook({
    List<Institution>? institutions,
    List<CashAccount>? accounts,
    List<CreditCardAccount>? cards,
    List<LoanAccount>? loans,
    List<AssetRecord>? assets,
    List<IncomeSource>? incomeSources,
    List<LedgerEntry>? entries,
    this.selectedBudgetTemplateId,
  })  : institutions = institutions ?? [],
        accounts = accounts ?? [],
        cards = cards ?? [],
        loans = loans ?? [],
        assets = assets ?? [],
        incomeSources = incomeSources ?? [],
        entries = entries ?? [];

  final List<Institution> institutions;
  final List<CashAccount> accounts;
  final List<CreditCardAccount> cards;
  final List<LoanAccount> loans;
  final List<AssetRecord> assets;
  final List<IncomeSource> incomeSources;
  final List<LedgerEntry> entries;
  String? selectedBudgetTemplateId;

