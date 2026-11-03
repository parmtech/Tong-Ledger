# Permanent Engineering Handoff — Tong Ledger

**Source of truth:** https://github.com/parmtech/Tong-Ledger
**Owner:** ParmTech
**Licence:** Apache-2.0
**Product:** Premium, open-source, manual-first money manager with budget planning; Android-first Flutter source; optional Windows later.
**Current status:** Initial documentation and code foundation. **NOT production-ready**. Generated native Android/Windows projects and signed installers NOT supplied yet. Domain UI sample must never be used for real private data until encrypted persistence and QA.

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
