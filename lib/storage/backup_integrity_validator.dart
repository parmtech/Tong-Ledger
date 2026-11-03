import '../domain/balanced_journal.dart';
import '../domain/finance_models.dart';

/// Additional trust boundary for untrusted portable backups. The legacy
/// versioned JSON codec validates schema; this verifies entity relationships
/// and the independent double-entry shadow projection before import.
class BackupIntegrityValidator {
  const BackupIntegrityValidator._();

  static void validate(FinanceBook book) {
    final institutionIds = book.institutions.map((e) => e.id).toSet();
    final cashIds = book.accounts.map((e) => e.id).toSet();

    const maxCents = 100000000000000;
    bool safeSigned(int value) =>
        value >= -maxCents && value <= maxCents;
    bool safePositive(int value) =>
        value >= 0 && value <= maxCents;

    for (final bank in book.institutions) {
      if (bank.name.trim().isEmpty || bank.name.length > 200) {
        throw const FormatException('Invalid institution name.');
      }
    }
    for (final account in book.accounts) {
      if (account.name.trim().isEmpty ||
          account.name.length > 200 ||
          !safeSigned(account.openingCents)) {
        throw const FormatException('Invalid account opening balance or name.');
      }
    }
    for (final card in book.cards) {
      if (card.name.trim().isEmpty ||
          !safePositive(card.limitCents) ||
          !safeSigned(card.openingOwedCents)) {
        throw const FormatException('Invalid credit card amount or name.');
      }
    }
    for (final loan in book.loans) {
      if (loan.name.trim().isEmpty ||
          loan.lenderName.trim().isEmpty ||
          !safePositive(loan.openingOutstandingCents) ||
          (loan.instalmentCents != null &&
              !safePositive(loan.instalmentCents!))) {
        throw const FormatException('Invalid loan principal, payment or lender.');
      }
    }
    for (final asset in book.assets) {
      if (asset.name.trim().isEmpty ||
          !safePositive(asset.valuationCents)) {
        throw const FormatException('Invalid asset valuation or name.');
      }
    }
    for (final income in book.incomeSources) {
      if (income.name.trim().isEmpty ||
          !safePositive(income.expectedCents) ||
          income.cadence.trim().isEmpty) {
        throw const FormatException('Invalid income source or forecast.');
      }
    }

    for (final account in book.accounts) {
      final bank = account.institutionId;
      if (bank != null && !institutionIds.contains(bank)) {
        throw const FormatException(
          'Account is linked to an unknown institution.',
        );
      }
    }
    for (final card in book.cards) {
      final issuer = card.institutionId;
      if (issuer != null && !institutionIds.contains(issuer)) {
        throw const FormatException(
          'Credit card is linked to an unknown institution.',
        );
      }
    }
    for (final loan in book.loans) {
      final lender = loan.institutionId;
      if (lender != null && !institutionIds.contains(lender)) {
        throw const FormatException(
          'Loan is linked to an unknown institution.',
        );
      }
    }
    for (final income in book.incomeSources) {
      final target = income.destinationAccountId;
      if (target != null && !cashIds.contains(target)) {
        throw const FormatException(
          'Income source references an unknown destination account.',
        );
      }
    }

    try {
      BalancedJournal.fromLegacy(book);
    } on JournalIntegrityException {
      throw const FormatException(
        'Financial entries in backup failed accounting integrity checks.',
      );
    }
  }
}
