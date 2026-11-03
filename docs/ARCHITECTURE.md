# Architecture — Android First, Flutter Shared Source

## Target design
Flutter presentation layer (adaptive Material 3) → application use-cases (commands/queries) → pure Dart financial domain (Money, Ledger, Budget) → repositories (abstract interfaces) → encrypted local data store. Platform adapters: notifications, biometrics, backups, window integration. Future cloud sync sits behind interface, never within calculation engine. Android release first; later desktop/iOS share calculation and UX foundations but require platform-specific build/signing.

## Module/folder plan
~~~text
lib/
  main.dart
  app/                     # root navigation, theme
  domain/                  # deterministic no Flutter dependency
    finance_models.dart
    ledger_engine.dart
    budget_templates.dart
  features/                # bank/accounts/cards/loans/budgets UI
  persistence/             # encrypted storage interface and migrations (milestone 2)
  design/                  # icons, colour tokens, adaptive components
assets/brand/              # trademark-cleared art
android/                    # generated with flutter create, Android-only first
test/                       # domain and widget tests
docs/                       # permanent project source of truth
.github/workflows/          # Android-first CI
~~~

## Security boundaries
- UI never stores passcodes or bank credentials. No live bank connection in v1.
- All financial amounts use integer minor units (AUD cents); no floating arithmetic.
- Data store is a **future protected boundary**; until encryption is built, prototype uses fictitious in-memory data only, clearly labelled.
- No arbitrary SDK-based analytics or third-party account data transfer.
- Backup operations shall be authenticated, encrypted, tamper-checked, and safely recoverable.
- Credentials/secrets never in repository, GitHub logs or crash reports.

## Ledger invariants
1. Deposit account to account transfer always sums to zero across linked cash accounts.
2. A card purchase increases card liability and categorised spending, not cash outflow.
3. A card repayment reduces cash and card debt but is not a second expense.
4. Loan repayment reduces cash; only interest/fee portion counted as spending, principal is balance-sheet transfer.
5. Forecast amounts and budget allocations cannot change actual balances.
6. Opening balances are recorded separately from earned income.
7. Every money mutation returns the corresponding activity ID and is reversible via a correction entry rather than destroying audit history.

## Persistence proposal
Adopt Drift/SQLite plus reviewed authenticated encryption and OS-protected keys; adapter tests on Android and Windows. Domain models are independent of persistence implementation. Keep explicit schema migrations, transaction atomicity, date/timezone standards and deterministic sample fixtures. Do not ship unencrypted financial storage. Use repository interfaces and dependency injection so widget tests never touch physical storage.

## Build/release boundaries
CI: flutter format check, flutter analyze, flutter test, Android debug APK. Production release: signed AAB from approved keystore, policy, accessibility, encryption and beta testing gates; iOS/macOS/Linux builds disabled now. Windows EXE only after dedicated workflow and distribution/signing decisions. Avoid creating bogus installer links.
