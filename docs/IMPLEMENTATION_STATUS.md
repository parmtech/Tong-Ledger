# Tong Ledger — Implementation Status

**Updated:** 2026-11-03 · **Development milestone v0.2 foundation on main**  
**Merged:** [PR #1](https://github.com/parmtech/Tong-Ledger/pull/1), squash commit `26ee173377f09837ee9c21397ad1e7fc554fffc3`  
**Verified:** [GitHub Actions run #41627444476](https://github.com/parmtech/Tong-Ledger/actions/runs/41627444476) — analyse, unit/widget tests, Android debug build, and artifact upload all **successful**. The debug APK artifact expires 2026-11-17.

## Implemented
- Flutter Android-first prototype and global Home/Money/Plans/Insights/More navigation.
- Manual banks, multi-accounts, credit cards, bank-linked or private-lender loans, assets, income sources and expense/payment/transfer entry forms.
- Versioned finance data codec and AES-256-GCM **encrypted local snapshot** with separate secure OS key, atomic write, fail-closed load and no silent reset.
- Fictional sample data isolated from real local vault; real data starts empty.
- Income/expense, transfers, credit purchases/payments, loan principal vs interest calculations, net worth estimate.
- 30 actual budget plan presets in six groups. Selected plan persists, but editing category percentages is still future work.
- Tests for ledger invariants, 30 plans, encrypted document authentication/tamper, data codec round trip and fake-store widget flows.
- Fully documented product blueprint, UX specification, security plan, code handoff and GitHub Wiki-style page.

## NOT production ready
- No user-controlled secure backup/restore, migration recovery, PIN/biometrics, full edit/archive/delete/reconciliation, complete custom budget engine, bills and scheduling or currency support beyond AUD calculations.
- Encrypted snapshot is not an encrypted transactional SQLite database; future migration/journaling/performance work required.
- An Android debug APK exists for tester exploration but is **not a signed Google Play release** and not yet personally device-tested.
- iOS, Windows, macOS and Linux binaries are not built; Flutter portability remains the longer-term plan.
- No bank connection or automatic real banking feed. Test with fictional balances only until backup/recovery and device security validation.

## Next engineering gate
1. Review and exercise debug APK with fake data on real Android devices; test restart persistence, failed key/restore and low storage.
2. Build user-editable independent budget plans from the 30 presets, link transactions to categories, integrate bills and goals.
3. Add encrypted backup/export/import, robust transaction storage, edit/archive workflow and full audit trail.
4. Finish accessibility, security review, release signing, privacy and financial Play declarations, beta testing.

Source: [STORAGE_DESIGN](STORAGE_DESIGN.md) · [MASTER_BLUEPRINT](MASTER_BLUEPRINT.md) · [TEST_PLAN](TEST_PLAN.md)
