# Changelog

All notable changes to Tong Ledger are tracked here. This project is in pre-release development; do not interpret milestones as signed releases.

## Unreleased — foundation (2026-11-03)

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
