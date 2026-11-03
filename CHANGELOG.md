# Changelog

All notable changes to Tong Ledger are tracked here. This project is in pre-release development; do not interpret milestones as signed releases.

## Unreleased — Android v0.3 personal budgets (2026-11-03)

- Merged [PR #2](https://github.com/parmtech/Tong-Ledger/pull/2) in `790a585ad83153ff733187e1f0cb22e7f1538893`.
- Added separate editable budget books, new blank budget, template clone, edit/duplicate/delete, category amount allocation, weekly/fortnightly/monthly/yearly cycle, start date and overbudget warning.
- Added category-by-category actual spending progress, with correct exclusion of transfers, card repayments and loan principal.
- Added schema-v1-compatible optional personal-budget persistence to existing encrypted snapshot.
- Added tests for budget period rollover, independent template clones, expense/refund recognition, old vault compatibility and UI save.
- CI [run 41634486712](https://github.com/parmtech/Tong-Ledger/actions/runs/41634486712): Flutter analyse, **26 tests**, Android debug APK build and artifact upload successful.
- **Development/testing only:** no secure backup and no Google Play signed production release.

## Unreleased — encrypted local vault development milestone (2026-11-03)

- Merged [PR #1](https://github.com/parmtech/Tong-Ledger/pull/1) in commit `26ee173377f09837ee9c21397ad1e7fc554fffc3`.
- Added AES-256-GCM local file storage, OS-protected encryption key, versioned full finance snapshot, atomic save and fail-closed error handling.
- Added real local manual data entries, account transfers, assets and income-source setup, kept fictional demo separate.
- Added tests for encryption authentication, schema integrity and widget local-vault behaviour.
- Passed Flutter analysis, all tests and Android debug APK build on [CI run 41627444476](https://github.com/parmtech/Tong-Ledger/actions/runs/41627444476).
- Still pre-release, no signed AAB, reliable backup/recovery or device security audit; do not enter private finance data.

## Previous — foundation (2026-11-03)

### Added
- Public open-source GitHub repository with Apache 2.0 license and Flutter ignore configuration.
- A-to-Z product blueprint, bank/card/loan data model, luxury UX, privacy/security guidance, A-to-Z wiki-style documentation portal, full tutorial outline and Android-first roadmap.
- Thirty complete ready-made budget plan presets in six collections, with documented categories and percentages.
- Pure Dart financial domain model, fixed-point AUD cents parsing/formatting and ledger calculations.
- Financial ledger treatment of cash transfers, credit card purchases/repayments, private lender loans with principal/interest, income/expense transactions and refunds.
- Flutter Material 3 developer demo: Home, Money, Plans, Insights, More with manual-entry dialogs and fictional showcase data.
- Domain and widget test source, Android debug CI workflow, editable open-source SVG mark.

### Fixed
- Bank-linked loan option added to demo entry flow; invalid fields exit safely.

### Not yet implemented / not verified
- Encrypted persistent data, full bank/loan editing and reconciliation, budget plan copy/save/edit, complete tutorials, backup/restore, full accessible responsive styling and production release signing.
- No production APK/AAB or Windows EXE supplied; Flutter tests and Android build are **not verified** by the current session.
