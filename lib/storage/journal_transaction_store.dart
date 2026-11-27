import '../domain/balanced_journal.dart';

/// Immutable read state for a single logical journal.
class JournalRevision {
  const JournalRevision({required this.number, required this.journal});

  final int number;
  final BalancedJournal journal;
}

class JournalWriteConflict implements Exception {
  const JournalWriteConflict();
}

/// A database adapter must implement compare-and-append in one durable
/// transaction, including the revision check and every posting. A failed
/// operation must leave the previously committed revision unchanged.
/// The contract does not itself provide encryption or persistence.
abstract interface class JournalTransactionStore {
  Future<JournalRevision> read();

  Future<JournalRevision> append({
    required int expectedRevision,
    required JournalBatch batch,
  });
}

/// Reference implementation for contract tests and use-case development.
/// Not a durable database. Not connected to the production vault.
class MemoryJournalTransactionStore implements JournalTransactionStore {
  MemoryJournalTransactionStore(BalancedJournal initial)
      : _state = JournalRevision(number: 0, journal: initial);

  JournalRevision _state;

  @override
  Future<JournalRevision> read() async => _state;

  @override
  Future<JournalRevision> append({
    required int expectedRevision,
    required JournalBatch batch,
  }) async {
    final previous = _state;
    if (previous.number != expectedRevision) {
      throw const JournalWriteConflict();
    }
    // Validation precedes publication, with no asynchronous gap between
    // the revision check and publication in this single-isolate adapter.
    final candidate = BalancedJournal(
      accounts: previous.journal.accounts,
      batches: [...previous.journal.batches, batch],
    );
    _state = JournalRevision(
      number: previous.number + 1,
      journal: candidate,
    );
    return _state;
  }
}
