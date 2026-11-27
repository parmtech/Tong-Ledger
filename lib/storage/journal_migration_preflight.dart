import '../domain/balanced_journal.dart';
import '../domain/ledger_engine.dart';
import 'backup_integrity_validator.dart';
import 'finance_book_codec.dart';

/// In-memory migration gate only. Never writes a vault or database.
/// Source and candidate must contain the same canonical legacy records,
/// including metadata, budget plans and transaction ordering.
class JournalMigrationPreflight {
  const JournalMigrationPreflight._();

  static BalancedJournal verify({
    required String sourceSnapshot,
    required String candidateSnapshot,
  }) {
    final source = FinanceBookCodec.decode(sourceSnapshot);
    final candidate = FinanceBookCodec.decode(candidateSnapshot);
    BackupIntegrityValidator.validate(source);
    BackupIntegrityValidator.validate(candidate);

    if (FinanceBookCodec.encode(source) != FinanceBookCodec.encode(candidate)) {
      throw const FormatException('Migration candidate changes source records.');
    }

    final legacy = calculateLedger(source);
    final journal = BalancedJournal.fromLegacy(candidate);
    final projection = journal.project(candidate);
    if (!_sameBalances(legacy.accounts, projection.cashAccounts) ||
        !_sameBalances(legacy.cardsOwed, projection.cardsOwed) ||
        !_sameBalances(legacy.loansOutstanding, projection.loansOwed) ||
        legacy.incomeCents != projection.incomeCents ||
        legacy.expenseCents != projection.expenseCents) {
      throw const FormatException('Migration candidate changes ledger balances.');
    }
    return journal;
  }

  static bool _sameBalances(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);
}
