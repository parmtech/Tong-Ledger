# P0 Balanced Journal — Incremental Migration Bridge

**Status:** Developer-only, pure Dart, read-only projection of the existing v0.3 `LedgerEntry` model. Does **not** modify the production FinanceBook shape, encrypted snapshot, persisted schema, or Android UI. This is one step toward the audited [Financial Domain v2](FINANCIAL_DOMAIN_V2.md), **not** a complete immutable event journal.

## Rationale

The current finance engine uses hand-written balance changes based on transaction type. This works for simple scenarios but cannot prove every action preserves double-entry integrity. A second, independent calculation path lets us test old balances against debit/credit postings **before changing historical data or storage**.

## Implemented on this branch

- `lib/domain/balanced_journal.dart` defines immutable-looking read-only objects: `JournalAccount`, `JournalPosting`, `JournalBatch`, `BalancedJournal`, `JournalBalances`, `JournalIntegrityException`.
- All eight v0.3 types map to balanced postings: income, cash expense, transfer, credit-card purchase, credit-card repayment, loan repayment with principal/interest split, card refund and cash refund.
- Manual opening cash and card/loan liabilities are paired with a synthetic `openingEquity` ledger. **Opening balances are not income or expense.**
- Validation rejects unknown ledger IDs, currency mismatches, non-positive/unsafe amounts, duplicate transaction IDs, unsupported posting counts, same-account transfers, bad loan interest splits, principal repayment beyond recorded outstanding debt, and unbalanced debit/credit batches.
- `BigInt` is used for debit/credit equality checks to avoid an overflow masking mismatches.
- The journal is currently **AUD-only** (existing v0.3 records have no currency fields). Explicit currency codes are included in the new posting model for later extension.
- `BalancedJournal.fromLegacy(book).project(book)` calculates separate cash balances, credit card/loan owed, posted income and posted expense.
- Synthetic opening batch timestamps are placeholders, **not** historical opening as-of dates. Original records do not yet store as-of values.
- Negative cash balances and negative credit-card balance (customer credit) are supported.
- Multiple transaction types are audited without double counting card repayment, bank transfer or loan principal. Refunds subtract from expense.

## Regression gates

`test/domain/balanced_journal_test.dart` compares this projection with the old `calculateLedger(book)` for a realistic eight-event mixed scenario and the fictional app demo; checks debit-credit balance and invalid inputs; confirms source entries are unmodified and projected batches cannot be appended.

**Important design choice:** The new journal is not called on every save or used as the source of UI balances yet. Before activating such validation in production, run realistic historic-fixture parity tests (including anomalous but previously accepted data), migration and device-recovery tests. Failing closed on an old legitimate vault without a recovery path could be data lockout.

## Next engineering slices

1. Stable entity/category identifiers; validate all institution links and currency scope.
2. Posting events with effective dates, immutable reversal/correction chains and IDs that can be persisted.
3. Define safe opening balance **as-of** and historical reconciliation rules.
4. Migrate encrypted v0.3 snapshots into a transaction-safe encrypted journal store via a **staging copy**; retain original ciphertext and tested rollback path.
5. Review experimental `feature/v0.4-backup-recovery` separately, including key invalidation recovery; do not merge it just because this projection is green.
6. Only then switch app financial display and write path to the journal.

## Not implemented

No SQL journal persistence, financial event revision chain, split categories, imports, reconcile workflow, multi-currency exchange, device restore/rekey, or user-facing functional redesign. No Play release claims. No real financial data should be used for testing.
