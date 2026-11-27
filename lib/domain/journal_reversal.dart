import 'balanced_journal.dart';

/// Pure, additive reversal of an existing legacy transaction projection.
/// This is a domain primitive, not yet a persisted correction or a UI action.
/// Opening balances require a separate reconciliation policy.
class JournalReversal {
  const JournalReversal._();

  static BalancedJournal append({
    required BalancedJournal journal,
    required String originalId,
    required DateTime effectiveAt,
  }) {
    if (!originalId.startsWith('transaction/')) {
      throw const JournalIntegrityException('Only transaction batches can be reversed.');
    }
    JournalBatch? original;
    final reversalId = 'reversal/$originalId';
    for (final batch in journal.batches) {
      if (batch.id == reversalId) {
        throw const JournalIntegrityException('Transaction already reversed.');
      }
      if (batch.id == originalId) original = batch;
    }
    if (original == null) {
      throw const JournalIntegrityException('Original transaction not found.');
    }
    if (effectiveAt.isBefore(original.at)) {
      throw const JournalIntegrityException('Reversal predates original transaction.');
    }
    final reversal = JournalBatch(
      id: reversalId,
      at: effectiveAt,
      category: original.category,
      postings: [
        for (final posting in original.postings)
          JournalPosting(
            accountId: posting.accountId,
            side: posting.side == JournalSide.debit
                ? JournalSide.credit
                : JournalSide.debit,
            amountCents: posting.amountCents,
            currency: posting.currency,
          ),
      ],
    );
    return BalancedJournal(
      accounts: journal.accounts,
      batches: [...journal.batches, reversal],
    );
  }
}
