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
