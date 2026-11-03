import 'finance_models.dart';

/// A read-only, deterministic double-entry view of the v0.3 ledger.
///
/// IMPORTANT: This is an additive, in-memory migration bridge. Legacy entries
/// remain the source of truth; this file neither rewrites the encrypted vault
/// nor claims the app already has a durable append-only journal.
enum JournalSide { debit, credit }

enum JournalAccountType { cashAsset, cardLiability, loanLiability, income, expense, openingEquity }

class JournalIntegrityException implements Exception {
  const JournalIntegrityException(this.message);
  final String message;

  @override
  String toString() => 'Journal integrity: $message';
}

class JournalAccount {
  const JournalAccount({
    required this.id,
    required this.type,
    this.currency = 'AUD',
  });
  final String id;
  final JournalAccountType type;
  final String currency;
}

class JournalPosting {
  const JournalPosting({
    required this.accountId,
    required this.side,
    required this.amountCents,
    this.currency = 'AUD',
  });

  final String accountId;
  final JournalSide side;
  final int amountCents;
  final String currency;
}

class JournalBatch {
  JournalBatch({
    required this.id,
    required this.at,
    required Iterable<JournalPosting> postings,
    this.category,
  }) : postings = List.unmodifiable(postings);

  final String id;
  final DateTime at;
  final List<JournalPosting> postings;
  final String? category;

  /// Each supported currency must balance within a transaction on its own.
  /// BigInt avoids masking overflow when checking malicious imported amounts.
  void validate(Map<String, JournalAccount> accounts) {
    if (id.trim().isEmpty || postings.length < 2 || postings.length > 16) {
      throw const JournalIntegrityException('A batch needs an ID and 2–16 postings.');
    }
    final debit = <String, BigInt>{};
    final credit = <String, BigInt>{};

    for (final posting in postings) {
      final ledger = accounts[posting.accountId];
      if (ledger == null || ledger.currency != posting.currency) {
        throw const JournalIntegrityException('Unknown ledger or currency mismatch.');
      }
      if (posting.amountCents <= 0 || posting.amountCents > 100000000000000) {
        throw const JournalIntegrityException('Posting amount outside safe bounds.');
      }
      final side = posting.side == JournalSide.debit ? debit : credit;
      side[posting.currency] =
          (side[posting.currency] ?? BigInt.zero) +
          BigInt.from(posting.amountCents);
    }
    for (final currency in {...debit.keys, ...credit.keys}) {
      if (debit[currency] != credit[currency]) {
        throw const JournalIntegrityException('Unbalanced postings for currency.');
      }
    }
  }
}

class JournalBalances {
  const JournalBalances({
    required this.cashAccounts,
    required this.cardsOwed,
    required this.loansOwed,
    required this.incomeCents,
    required this.expenseCents,
  });

  final Map<String, int> cashAccounts;
  final Map<String, int> cardsOwed;
  final Map<String, int> loansOwed;
  final int incomeCents;
  final int expenseCents;

  int get cashCents => cashAccounts.values.fold(0, (a, b) => a + b);
  int get cardDebtCents => cardsOwed.values.fold(0, (a, b) => a + b);
  int get loanDebtCents => loansOwed.values.fold(0, (a, b) => a + b);
}

class BalancedJournal {
  BalancedJournal({
    required Map<String, JournalAccount> accounts,
    required Iterable<JournalBatch> batches,
  })  : accounts = Map.unmodifiable(accounts),
        batches = List.unmodifiable(batches) {
    final seen = <String>{};
    for (final batch in this.batches) {
      if (!seen.add(batch.id)) {
        throw const JournalIntegrityException('Duplicate journal batch ID.');
      }
      batch.validate(this.accounts);
    }
  }

  final Map<String, JournalAccount> accounts;
  final List<JournalBatch> batches;

  /// Signed balances: cash and expense are debit-normal, while loan/card
  /// liabilities, income, and opening equity are credit-normal.
  Map<String, int> get balances {
    final totals = <String, int>{for (final key in accounts.keys) key: 0};
    for (final batch in batches) {
      for (final posting in batch.postings) {
        final account = accounts[posting.accountId]!;
        final normalDebit = account.type == JournalAccountType.cashAsset ||
            account.type == JournalAccountType.expense;
        final positive = (posting.side == JournalSide.debit) == normalDebit;
        final delta = positive ? posting.amountCents : -posting.amountCents;
        totals[posting.accountId] = totals[posting.accountId]! + delta;
      }
    }
    return Map.unmodifiable(totals);
  }

  JournalBalances project(FinanceBook book) {
    final b = balances;
    return JournalBalances(
      cashAccounts: Map.unmodifiable({
        for (final a in book.accounts) a.id: b['cash:${a.id}']!,
      }),
      cardsOwed: Map.unmodifiable({
        for (final a in book.cards) a.id: b['card:${a.id}']!,
      }),
      loansOwed: Map.unmodifiable({
        for (final a in book.loans) a.id: b['loan:${a.id}']!,
      }),
      incomeCents: b['income:posted']!,
      expenseCents: b['expense:posted']!,
    );
  }

  /// All existing entries are projected without altering persisted records.
  /// The opening equity ledger is a balancing account, NOT earned income.
  factory BalancedJournal.fromLegacy(FinanceBook book) {
    final accounts = <String, JournalAccount>{
      'equity:opening': const JournalAccount(
        id: 'equity:opening', type: JournalAccountType.openingEquity),
      'income:posted': const JournalAccount(
        id: 'income:posted', type: JournalAccountType.income),
      'expense:posted': const JournalAccount(
        id: 'expense:posted', type: JournalAccountType.expense),
    };
    final batches = <JournalBatch>[];

    JournalPosting debit(String key, int cents) => JournalPosting(
      accountId: key, side: JournalSide.debit, amountCents: cents);
    JournalPosting credit(String key, int cents) => JournalPosting(
      accountId: key, side: JournalSide.credit, amountCents: cents);

    void opening(
      String key, int signedCents, bool debitNormal, String identifier,
    ) {
      if (signedCents == 0) return;
      if (signedCents.abs() > 100000000000000) {
        throw const JournalIntegrityException('Opening amount exceeds bounds.');
      }
      final increaseNormal = signedCents > 0;
      final side = debitNormal == increaseNormal
          ? JournalSide.debit : JournalSide.credit;
      batches.add(JournalBatch(
        id: 'opening/$identifier',
        at: DateTime.utc(1970),
        postings: [
          JournalPosting(accountId: key, side: side,
            amountCents: signedCents.abs()),
          JournalPosting(
            accountId: 'equity:opening',
            side: side == JournalSide.debit
                ? JournalSide.credit : JournalSide.debit,
            amountCents: signedCents.abs(),
          ),
        ],
      ));
    }

    void register(String key, JournalAccountType type) {
      if (accounts.containsKey(key)) {
        throw const JournalIntegrityException('Duplicate financial account ID.');
      }
      accounts[key] = JournalAccount(id: key, type: type);
    }

    for (final a in book.accounts) {
      final key = 'cash:${a.id}';
      register(key, JournalAccountType.cashAsset);
      opening(key, a.openingCents, true, key);
    }
    for (final card in book.cards) {
      final key = 'card:${card.id}';
      register(key, JournalAccountType.cardLiability);
      opening(key, card.openingOwedCents, false, key);
    }
    for (final loan in book.loans) {
      final key = 'loan:${loan.id}';
      register(key, JournalAccountType.loanLiability);
      opening(key, loan.openingOutstandingCents, false, key);
    }

    void require(String key) {
      if (!accounts.containsKey(key)) {
        throw const JournalIntegrityException('Entry references a missing account.');
      }
    }

    final seen = <String>{};
    final loanOutstanding = {
      for (final l in book.loans) l.id: l.openingOutstandingCents,
    };
    for (final entry in book.entries) {
      if (entry.id.trim().isEmpty || !seen.add(entry.id)) {
        throw const JournalIntegrityException('Empty or duplicate transaction ID.');
      }
      final amount = entry.amountCents;
      if (amount <= 0 || amount > 100000000000000) {
        throw const JournalIntegrityException('Invalid transaction amount.');
      }
      if (entry.interestCents < 0 || entry.interestCents > amount) {
        throw const JournalIntegrityException('Invalid loan interest split.');
      }
      final p = <JournalPosting>[];
      String cashSource() {
        final key = 'cash:${entry.sourceAccountId ?? ''}';
        require(key);
        return key;
      }
      String cashDestination() {
        final key = 'cash:${entry.destinationAccountId ?? ''}';
        require(key);
        return key;
      }
      String card() {
        final key = 'card:${entry.cardId ?? ''}';
        require(key);
        return key;
      }
      String loan() {
        final key = 'loan:${entry.loanId ?? ''}';
        require(key);
        return key;
      }

      switch (entry.type) {
        case LedgerType.income:
          p.add(debit(cashDestination(), amount));
          p.add(credit('income:posted', amount));
        case LedgerType.cashExpense:
          p.add(debit('expense:posted', amount));
          p.add(credit(cashSource(), amount));
        case LedgerType.transfer:
          final from = cashSource();
          final to = cashDestination();
          if (from == to) {
            throw const JournalIntegrityException('Cannot transfer to the same account.');
          }
          p.add(debit(to, amount));
          p.add(credit(from, amount));
        case LedgerType.cardPurchase:
          p.add(debit('expense:posted', amount));
          p.add(credit(card(), amount));
        case LedgerType.cardPayment:
          p.add(debit(card(), amount));
          p.add(credit(cashSource(), amount));
        case LedgerType.loanPayment:
          final target = loan();
          final id = entry.loanId!;
          final principal = amount - entry.interestCents;
          if (principal > loanOutstanding[id]!) {
            throw const JournalIntegrityException('Loan principal exceeds amount owed.');
          }
          loanOutstanding[id] = loanOutstanding[id]! - principal;
          if (principal > 0) p.add(debit(target, principal));
          if (entry.interestCents > 0) {
            p.add(debit('expense:posted', entry.interestCents));
          }
          p.add(credit(cashSource(), amount));
        case LedgerType.cardRefund:
          p.add(debit(card(), amount));
          p.add(credit('expense:posted', amount));
        case LedgerType.cashRefund:
          p.add(debit(cashDestination(), amount));
          p.add(credit('expense:posted', amount));
      }
      batches.add(JournalBatch(
        id: 'transaction/${entry.id}',
        at: entry.at, category: entry.category, postings: p,
      ));
    }

    return BalancedJournal(accounts: accounts, batches: batches);
  }
}
