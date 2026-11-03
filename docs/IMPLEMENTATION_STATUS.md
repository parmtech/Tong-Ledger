# Implementation Status — Tong Ledger

**Updated:** 2026-11-03  
**App version in pubspec:** 0.1.0+1 (development foundation, not a released version)  
**Project:** Public, Apache-2.0; Android first with Flutter shared-source strategy.

## Completed — committed to main
- Product scope, detailed A-to-Z blueprint, 30 real budget plan allocations (6 groups of 5), UX, architecture, data model, tutorials, privacy, tests, roadmap, contributor handoff.
- README brand logo and version-controlled wiki-style home page.
- Pure Dart models for institutions, multiple cash accounts, cards, loans, assets, income sources and entries.
- Ledger calculation for cash income/expense, bank transfer, card purchase, card payment, loan payment with principal/interest, refunds.
- Fixed-point AUD cents formatter/parser; budget template allocation algorithm.
- Demo data using a bank with 3 accounts, one card, one independent car loan and assets.
- Flutter Material 3 app shell with Home / Money / Plans / Insights / More navigation.
- **Temporary demo-only** dialogs to add institutions, accounts, cards, private loans, income, expenses, card purchases/payments and loan repayments.
- Tests for ledger invariants, fixed-point money and 30 template allocation totals.
- GitHub Actions workflow intended to generate Android platform files, run analyse/test and build **debug** APK.

## NOT complete — blockers before real use
- Real encrypted local SQLite/Drift persistence; all prototype edits currently disappear on restart.
- Fully validated bank/loan linked institution UX, all CRUD and import, audit log, data reconciliations and multi-currency.
- Budget template clone/save/edit UI, custom categories/periods/rollover, expenses link across budget scopes.
- Secure backup/export and restore, PIN/biometrics, permissions, privacy settings and release threat review.
- Complete visual polishing, full tutorials and localisation, accessibility/benchmarking.
- Release signing setup, Android native project committed as pinned reproducible scaffold, Play Store policy and testing.
- CI has not been confirmed green through available tools at time of this update. No APK/AAB/EXE is claimed as tested or released.

## Next actions in priority order
1. Verify GitHub Actions workflow is enabled and inspect the first run on Actions page; fix any build/test issues.
2. Implement encrypted local storage and schema migrations; persist institutions/accounts/card/loan/entries with atomic transactions.
3. Add proper input validation and stable UI create/edit/archive/delete including linking banks and lenders.
4. Implement budget plan copying, editable allocations and tracking actual transaction categories.
5. Complete privacy/accessibility/performance/backup test gates; only then create release APK/AAB.

## Developer handoff rule
Any developer or AI continuing this repo must update this status, HANDOFF and TEST_PLAN with what truly passed, what is incomplete, and links to commits/workflow runs. Do not claim tested builds without a verified outcome. Never use real user finance records for development fixtures.
