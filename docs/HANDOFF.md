# Permanent Engineering Handoff — Tong Ledger

**Source of truth:** https://github.com/parmtech/Tong-Ledger
**Owner:** ParmTech
**Licence:** Apache-2.0
**Product:** Premium, open-source, manual-first money manager with budget planning; Android-first Flutter source; optional Windows later.
**Current status:** Android v0.2 encrypted-snapshot DEVELOPMENT foundation merged into main in PR #1. CI analysis/tests/debug APK build succeeded (run 41627444476). **NOT production-ready:** backup/recovery, comprehensive editing, PIN/biometrics and production signing remain outstanding. Use fictional data for device testing.

## Non-negotiable product-owner requirements
1. Manually add a bank, then any number of different savings/salary/expenses accounts under it. No online banking connection is required.
2. A bank can also contain multiple credit cards; show limit, amount owed and available credit. Cards have a separate global view.
3. Loans have their own **Loans** section and can be linked to a bank OR an independent private company, with customised lender name, type and repayment.
4. Assets, salary/business/freelance/irregular income and transactions must link to user-selected accounts/cards; default AUD.
5. **30 real ready-made BUDGET plans** grouped 6 × 5, editable and cloneable; not page skins, not loan templates.
6. Luxury, distinctive design; easy Quick Start + full tutorials; great novice and power-user experience.
7. Public open-source repository, Apache 2.0. Android build first; Flutter code portable to iPhone, Windows, macOS and Linux, but do NOT build those now except optional Windows later.
8. Do not double-count balance transfer, card payoff, loan principal, future income or available credit. No real money movement.

## First source milestone
Files: lib/domain/ (models, ledger, template engine), lib/app/, lib/main.dart, test/, .github/workflows/flutter-ci.yml and /docs. Show fake DEMO figures only. Storage deliberately not persisted until encrypted implementation is added. Future first implementation task = secure local data layer and CRUD forms.

## Contributor checklist
- Before work: read README, MASTER_BLUEPRINT, ARCHITECTURE, TEST_PLAN and this HANDOFF.
- Do not make private financial data or credential fixtures public.
- For each feature: add cases, tests and accessible error states; run flutter analyze/test and Android build on runner.
- Record commit/branch, verified tests, not-run tests, accepted decisions, blockers, and exact next steps here. Keep documents aligned with implementation; never claim feature is complete because it appears on a mockup.
- Avoid website/other ParmTech repo modifications. Change only Tong Ledger unless explicitly instructed.

## Initial risk list
Flutter SDK/Android SDK not installed in conversation container; source validation awaits real CI. Encrypted database and native platform shell pending. GitHub Actions runner network/availability not yet verified. Name clearance, app icon rights and store policies pending. These are explicit blockers before publishing.


## 2026-11-03 — initial implementation verified by GitHub fetch
- Source documentation commit: b54b5e856cd90adbf4321e0bcc999e7b286189e8.
- Flutter domain/main/widget/workflow files are committed on the public main branch; latest loan-linking fix commit: 59dba1f44ca3d1101e4916bb13f1191602a92270.
- Master blueprint, 30 plan catalogue, 30 matching Dart seed plans, luxury UX docs, tutorial guide, wiki-style home page and security/test/roadmap docs are in the SAME repo.
- Static GitHub source verification: 30 Dart plans in 6 groups; each sums to exactly 100%.
- CI: GitHub Actions YAML committed, but no green run was observable through available connected action results. Do not call tests or APK built successfully until verified.
- Next developer must verify Actions on https://github.com/parmtech/Tong-Ledger/actions, fix compilation/lint/test errors if any, then implement encrypted persistent finance storage and the complete forms.
- Android is the only current release target. No Windows, macOS, Linux or iOS package claimed.

## 2026-11-03 — verified v0.2 development milestone
- PR #1 merged in squash commit `26ee173377f09837ee9c21397ad1e7fc554fffc3`.
- CI [run 41627444476](https://github.com/parmtech/Tong-Ledger/actions/runs/41627444476) passed analyse, tests and Android debug APK build, artifact `tong-ledger-android-debug` expires 2026-11-17.
- v0.2 includes AES-GCM encrypted local snapshot with OS secure key, records for manually-added banks/accounts/cards/loans/assets/income and transactions, fictional demo isolation, plan selection persistence. See docs/STORAGE_DESIGN.md.
- Security and UX gaps remain: no backed-up recovery, no full edit/archive, no complete budget editor, no tested signed release; no device QA yet.
- Android first; no iPhone/macOS/Linux packages or Windows EXE delivered.
- Before future work, read the latest IMPLEMENTATION_STATUS.md and this appended note. Do NOT rely on older 'no encrypted storage' statements above; they describe the previous v0.1 milestone.

## 2026-11-03 — v0.3 merge and verified QA
- [PR #2](https://github.com/parmtech/Tong-Ledger/pull/2) merged commit `790a585ad83153ff733187e1f0cb22e7f1538893`.
- CI run [41634486712](https://github.com/parmtech/Tong-Ledger/actions/runs/41634486712) passed Flutter analyze, 26 tests, Android debug APK build and artifact upload. Artifact expires 2026-11-17.
- Implemented independent editable budget books under `lib/domain/budget_plan.dart` and `lib/features/budgets/budget_editor_page.dart`; existing cipher store serializes budgets through `FinanceBookCodec` without breaking v0.2 snapshots.
- User can create budget from one of 30 actual allocation templates, custom build, edit category amounts/name/income/period/date, duplicate and delete. Actual spending projection excludes card settlements/transfers and loan principal.
- Important: v0.3 has **no secure backup/restore** or signed production APK/AAB; phone loss/key invalidation can lose records. Do not claim production financial data safety.
- Next priority: secure backup/recovery and full edit/archive + device tests. Maintain Android-first code; cross-platform targets deferred.
