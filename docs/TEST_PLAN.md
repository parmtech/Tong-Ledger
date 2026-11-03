# Test Strategy & Quality Gates

## Domain calculations
- Deposit A starts A$1,000; transfer A$200 to deposit B; total cash unchanged.
- Card starts A$2,300 owed against A$8,000 limit => A$5,700 available. A$100 card purchase increases owed/spend by A$100, no bank debit. A$100 card payment then lowers bank cash and card owed by A$100, **not** adding expense again.
- Loan A$15,000, repayment A$600 including A$100 interest: cash -A$600, principal -A$500, expense +A$100; no double-counting.
- Income forecast does not credit account until actual income entry posts. Opening balance excluded from earnings.
- Refund/chargeback/reversal preserve history; zero, negative and overflow input are rejected correctly.
- Every transfer and card payment is atomic, valid references only. Identity checks across profiles.
- All 30 template allocations sum exactly 100 and clones cannot mutate source.

## UI tests
First launch, skippable tour, add bank + three accounts + card + independent loan, income frequency and landing account, expense from selected bank/card, budget picker and editor, screen rotation, 200% font, TalkBack, keyboard and tablet layout. Empty, saving, error, offline and no-data are distinct.

## Persistence and security tests — required later
Encrypted storage, backup password failures, re-keying, partial writes, corruption, crash during save, app lifecycle kill/restart, migration N-1/N, 10k+ transactions performance, reconciliation, long currency labels, device lock and backup restore, no PII logging.

## Release CI pipeline
1. flutter format / analyze / test.
2. Android debug APK build when generated Android shell exists.
3. Code review, dependencies/security checks and screenshot/golden review.
4. Production: release AAB, signed key verification, min/target SDK check, Play policy/privacy and listing, beta testers, staged release.

**Pass/fail policy:** A compile or test failure blocks calling the app build-ready. Tests not run locally must be reported as unverified; a workflow starting does not equal a green outcome.
