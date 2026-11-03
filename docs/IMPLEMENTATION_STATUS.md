# Tong Ledger — Implementation Status

> **2026-11-04: P0 accounting safety milestone merged:** [PR #4](https://github.com/parmtech/Tong-Ledger/pull/4), commit `ab88997915be62a17c333c8fa48fca96197530bd`. The new [balanced journal projection](JOURNAL_PROJECTION_BRIDGE.md) translates all eight legacy entry types into debit/credit postings **without writing or migrating a single persisted record**. [GitHub Actions run 41648816107](https://github.com/parmtech/Tong-Ledger/actions/runs/41648816107) passed Dart analysis, tests and Android debug APK build. This is a tested domain bridge, **not a new production app release, an immutable persisted journal, or a data recovery guarantee**.
>
> **Critical backup blocker:** [Issue #5](https://github.com/parmtech/Tong-Ledger/issues/5) documents why the experimental `feature/v0.4-backup-recovery` branch cannot recover an existing vault after Android device-key invalidation. This branch must remain unmerged pending a recovery-only path and real-device tests.


> **Blueprint audit merged to main:** [PR #3](https://github.com/parmtech/Tong-Ledger/pull/3), commit `6e55d3d2d3d0bee5002f613d2b011f74b01bdd61`. This is a **documentation-only** milestone, not a change to the installed app.
>
> **Planning update (2026-11-03):** [Master Blueprint v2](MASTER_BLUEPRINT_V2.md), [Full Audit](BLUEPRINT_AUDIT_2026_11_03.md), [UX v2](UX_INFORMATION_ARCHITECTURE_V2.md), [Finance Engine v2](FINANCIAL_DOMAIN_V2.md), [Roadmap v2](ENGINEERING_ROADMAP_V2.md) are **specification only** and do not update implemented v0.3 functionality. The experimental `feature/v0.4-backup-recovery` branch has not been reviewed/merged under these new gates. Latest verified code status below remains v0.3.


**Updated:** 2026-11-03 · **Current developer milestone: v0.3, merged to main**  
**Repository:** https://github.com/parmtech/Tong-Ledger  
**Status:** Android-first, open-source **development/testing** build only — not a production release.

## Latest verified milestone
- [PR #2](https://github.com/parmtech/Tong-Ledger/pull/2) merged at commit `790a585ad83153ff733187e1f0cb22e7f1538893`.
- [GitHub Actions run 41634486712](https://github.com/parmtech/Tong-Ledger/actions/runs/41634486712) **success**: Flutter analyse, 26 automated tests and Android debug APK build/artifact upload.
- APK artifact `tong-ledger-android-debug` is available from the Actions run (expires 2026-11-17).

## Implemented and committed
- Flutter Material 3 Android-first app with Home, Money, Plans, Insights and More.
- Manual institutions, multiple bank cash accounts, credit cards, loans with bank or independent lenders, assets, income sources, cash/card expenses, transfers and repayments.
- Fixed-point AUD ledger engine; transfers and card repayments do not double-count expenses, loan repayments separate principal and interest.
- Encrypted local file snapshot using AES-256-GCM and OS-protected key; fail-closed on bad key/data (not yet security-audited).
- Original bank data starts empty and is separate from explicit fictional demo.
- 30 real ready-made budget plans across six groups, all total 100%.
- **v0.3:** create custom budget, clone any preset, edit budget title, take-home income, pay frequency, cycle date and category names/amounts, plus duplicate/delete saved budgets.
- **v0.3:** budget allocations stored independently in encrypted vault; legacy v0.2 vaults with no budgets field migrate logically to empty list; template presets stay immutable.
- **v0.3:** planned-vs-actual spending by category, based on dated transactions, excludes transfers/card settlements/loan principal and handles refunds.
- Automated domain, codec, security smoke tests and widget tests (26 passed on the verified run).

## Not production ready; remaining work
1. **No secure user-controlled backup/recovery.** A lost device/key can result in data loss. Do not use this prototype for real important financial records.
2. No full transaction editing/archiving, budget category rules, user profiles, multi-currency reports, import/export, full bill/subscription scheduling or envelope rollover.
3. No biometric lock or comprehensive Android device-security review; encrypted snapshot is not yet a transaction-journaled encrypted database.
4. Android installed-device testing, low-storage/power-loss recovery and accessibility performance audits remain.
5. No Play Store signed AAB or approval, no published financial privacy declarations, no production support guarantee.
6. No iPhone, Windows, macOS or Linux binaries yet; portable Flutter source retained for later.

## Next developer priorities
- Implement independent secure backup/export and tested restore/key recovery without exposing secrets to cloud services.
- Add edit/archive/reconcile workflows and durable transaction journaling; migrate from single encrypted snapshot when safe.
- Add detailed bills/scheduled payments and account/category budget scopes.
- Improve premium UI, light/dark themes, multilingual tutorials, TalkBack and device performance.
- After security/recovery tests, generate signed Android AAB and complete Play Console policy/beta rollout.

All future contributors must update this status, HANDOFF, TEST_PLAN, CHANGELOG with exact tested/not-tested outcomes. Do not claim release or data recovery reliability based solely on CI compilation.
