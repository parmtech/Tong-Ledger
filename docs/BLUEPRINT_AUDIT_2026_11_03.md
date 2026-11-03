# Tong Ledger — Full Product Blueprint Audit (2026-11-03)

**Audit type:** design, feature scope, accounting correctness, technical architecture, security, UX accessibility, scalability, and release sequencing.  
**Baseline reviewed:** \`main\` at \`3fbee00f8500746d052d9a05f87a58314ec1c31f\` (v0.3 development state).  
**Audit output:** [Canonical v2 blueprint](MASTER_BLUEPRINT_V2.md), [UX navigation/design system](UX_INFORMATION_ARCHITECTURE_V2.md), [financial data contract](FINANCIAL_DOMAIN_V2.md), [architecture, security, execution roadmap](ENGINEERING_ROADMAP_V2.md).  
**Code policy:** **No new application code in this audit branch.** There is a separate in-progress \`feature/v0.4-backup-recovery\` branch. Do not merge it into main without revisiting this audit and verifying independent CI and device tests.  

## Executive diagnosis

Tong Ledger has a compelling **manual-first, offline-first** concept: banks hold multiple accounts/cards, loans may belong to private lenders, assets and income sources are independent records, and 30 real ready-made budget plans can be customised. The v0.3 Flutter demo is a functional foundation, not a polished consumer product. The main architectural risk is **building a broad feature inventory without a strict, explainable financial model and simple task-oriented information architecture**. The recommended approach is **correctness → recoverability → usability → expansion**.

### Assessment by dimension

| Dimension | Current strengths | Gap / result |
| --- | --- | --- |
| Product | Clear distinction between institutions, cash accounts, credit cards, loans, assets and budgets | Core release scope and user journey too broad; must introduce progressive disclosure |
| Navigation | Five bottom tabs, basic Money and Plans sections | "More" hides activities/critical actions; first-time user has too many concepts; no actionable empty-state system |
| Dashboard | Cash/cards/loans/net-worth metrics | Not prioritised around “what can I safely do today?”; inconsistent as-of dates; detail overload risk |
| Templates | 30 seed budget plans in six groups, 100% allocations, independent v0.3 copies | Discovery and personalisation weak, categories matched by free-text, no matching/selection wizard or realistic obligation warnings |
| Financial integrity | Transfer/card payoff/loan principal generally not counted twice in central calculations | Current code is NOT a true balanced, immutable double-entry journal; no reconciliation/history or correction model |
| Persistence | Local AES-GCM encrypted snapshot + Keystore-protected key | Whole-document rewrite, incomplete recovery and backup strategy, limited migrations and no tested interrupted-write recovery |
| Security | No bank credentials, fail-closed decrypt, separate future secure backup | Device recovery, attack-model tests, secure import/export, key lifecycle and app lock unresolved |
| Responsive design | Flutter/Dart portable foundation | Large-screen patterns and feature/platform boundary policies unspecified; current UI mostly a single large StatefulWidget |
| Accessibility | Blueprint mentions TalkBack and scaled text | No screen-level copy, dynamic type layout budget, accessibility QA scripts or contrast-measured palette |
| Release | GitHub Actions runs analysis/tests/debug APK | No pinned Android project, offline migrations/recovery QA, device tests, policy pack or signed AAB |
| Product operation | Public repo, docs, open-source license | Documentation conflicts with recent implementation in several older files; need canonical current status and decision log |

## Prioritised findings and corrective decisions

**Priority definitions:** **P0** = fix before public handling of real data, **P1** = required for smooth first consumer release, **P2** = planned post-release or optional. A feature's presence in a specification does NOT mean it is implemented.

| ID | Priority | Finding and evidence | User impact | Required correction | Acceptance gate |
| --- | --- | --- | --- | --- | --- |
| A01 | P0 | \`lib/domain/ledger_engine.dart\` updates projected balances by transaction type; there is no persisted balanced journal-posting structure or immutable adjustment/reversal chain. | Reconciliation, imports and corrections may create hard-to-debug wrong totals. | Introduce transaction header + balanced posting entries, immutable corrections and atomic writer; preserve finance invariants. | Every transaction's postings balance; reversal, refund and repayment tests pass. |
| A02 | P0 | \`lib/storage/secure_finance_store.dart\` rewrites one encrypted full snapshot. No verified backup/restoration from invalidated Android device key. | Device loss/corruption can destroy a user's only data copy. | Define portable encrypted backup, protected-file picker, snapshot integrity, key loss recovery, transactional migrations and failure tests before launch. | New-device restore, wrong password, interrupted write, old-version migration and rollback device tests. |
| A03 | P0 | \`FinanceBookCodec\` mostly validates JSON structure and ledger outcome; it does not comprehensively validate all institution/asset/income links, IDs, currencies or event ordering. | Orphan records, silent omissions, inconsistencies. | Enforce schema invariants with foreign keys and validation layer; reject malformed imports before commit. | Negative and fuzz tests per entity and relationship. |
| A04 | P0 | Current asset total is an unqualified sum of manually valued assets; values and debts may double-count when investment/cash representations overlap. | Misleading net worth. | Distinguish account balance vs separately valued assets, ownership %, valuation timestamps and category exclusion rules. | Net-worth examples for property/mortgage/investment/cash verified. |
| A05 | P0 | Current UI and documentation do not provide a complete tested recovery path before using real financial data. | False confidence about security. | **Never** treat a successful debug build as secure financial product. Add onboarding warning until recovery/release gates pass. | Signed production gate blocks if recovery incomplete. |
| A06 | P1 | Account/card/loan forms are generic, and setup currently demands many steps. | Beginner abandonment, confusing bank relationships. | Offer **Quick setup**, **Guided setup**, **Explore demo**, **Advanced**; ask only necessary fields, with edit later. | Typical beginner records first bank+account+expense in under ~3 minutes in moderated tests. |
| A07 | P1 | \`Home/Money/Plans/Insights/More\` navigation has no full Activity destination; users may be unable to find historical transactions. | Poor task discoverability. | Five clearly named tabs **Home, Money, Budget, Activity, Insights**; top-right profile/settings/help. One global Add action. | First-time users find transaction search, backup and card payment without instruction. |
| A08 | P1 | Home has many financial tiles with no differentiated priority/as-of badges. | Cognitive overload; available credit mistaken for cash. | Lead with **Cash snapshot**, **Upcoming obligations**, **Budget health**, **Recent activity**; cards and loans in compact group; show as-of and stale-data cues. | 5-second read test: users correctly identify cash, amount owed, next bill. |
| A09 | P1 | 30 budget templates appear as a long list despite six collections. | Choice paralysis. | Guided question chips, six collection cards, search and recommended short-list; show realistic obligations warning and preview before cloning. | Pick useful template in <1 minute, create independent editable copy. |
| A10 | P1 | Budget categories matched by raw display labels (string), not stable IDs; duplicate/renamed categories can break history. | Spending attribution changes unexpectedly after rename. | Stable category IDs, rename history, transaction classifications and optional account scope. | Category rename does not rewrite historical spending intent. |
| A11 | P1 | Income source expected amount is separate from actual deposits, but recurring bills and card due dates are still mostly planned. | Users conflate forecast and cash; miss payments. | Explicit **Scheduled / Due / Posted / Overdue** states, “Mark paid” confirms posting and account source. | No scheduled cash change until confirmed. |
| A12 | P1 | Loans lack full rate, amortisation, statement cycle, due date and private lender categories in implemented model. | Misleading debt projections. | Loan subtype + variable/fixed rate, split principal/interest, payment schedule, interest uncertainties and private lender linkage. | Example car loan, mortgage and private lender amortisation/override tests. |
| A13 | P1 | Credit card model currently tracks limit and owed but not statement balance/payment due/minimum and accrued fees. | Wrong “remaining” or recommended payment. | Distinguish available credit, current owed, statement owed, due and minimum; never label credit as money in cash. | Correct scenarios for overlimit, credit balance, refunds, billing-cycle changes. |
| A14 | P1 | Long screen forms have generic validation and little copy explaining the result of actions. | Increased input errors, friction. | Dedicated forms by object type with progressive fields, inline examples, preview before posting and save/undo feedback. | Zero silent failures; correct as-of and currency. |
| A15 | P1 | User-editable categories are free text; split transactions, refunds, merchant assignment and reconciliation not complete. | Budget totals can be inaccurate. | Canonical transaction category/subcategory IDs, optional split lines and reconciliation status, archive/reversal instead of destructive delete. | Double-entry and budget equality property tests. |
| A16 | P1 | One big app shell StatefulWidget handles routes, forms, persistence and presentation. | Regression and slower future UI work. | Feature-folder modules, typed navigation, use-case services, repository boundary, small testable widgets, dependency injection. | UI tests and domain tests isolated; no direct FS access from widgets. |
| A17 | P1 | Full accessibility/mobile robustness is aspirational, not specified per screen. | Text clipping, illegible contrast, inaccessible controls. | Define screen contracts, loading/empty/error states, >=48dp targets, TalkBack labels, text scaling, reduced motion and golden tests. | Verified on small phones, 200% font, TalkBack, dark/light. |
| A18 | P1 | Root docs and \`pubspec.yaml\` version naming are not fully consistent with v0.3. | Developers/users may mistake prototypes for releases. | One canonical status page, accurate semantic version/build numbers, release checklist and human-facing beta disclaimer. | README/changelog/status/CI/artifact names agree. |
| A19 | P2 | Multi-currency and household sharing are desired but not fully scoped. | Future rewrite risk. | Stable ISO currency, money/exchange-rate provenance fields; optional household profile/permission and sync boundaries defined now, implemented later. | Domain portable without platform-specific imports. |
| A20 | P2 | AI/receipt OCR, bank sync and household cloud collaboration could balloon launch scope. | Delays correctness and Play approval. | Keep optional modules behind explicit interfaces, opt-in consent, no bank passwords; stage after Android stability. | No core dependency on AI/cloud/bank integrations. |
| A21 | P2 | Premium brand assets and Open Source license have separate rights requirements. | Legal/trademark surprises. | Keep proprietary/third-party logos out of Apache assumptions; use licensed or original icon/font sources and record attribution. | Assets rights ledger and store-name clearance. |
| A22 | P1 | Release CI checks logic but no on-device recovery and transaction-performance assurance. | Production loss/crashes. | Pair unit/property tests with widget, integration, real-device, migration, security, low-storage tests and signing audit. | No public release with any P0 failure. |

## Contradictions to resolve in existing documents

- **Old blueprint vs code:** \`MASTER_BLUEPRINT.md\` describes double-entry-safe postings and many fields as intended; this is an architectural **goal**, not current v0.3 implementation.
- **Old storage proposal vs v0.3:** \`ARCHITECTURE.md\` says encryption is future work while current code encrypts a snapshot; the next goal is resilient transactional **encrypted database**, not merely basic encryption.
- **Old README/HANDOFF status:** earlier paragraphs about in-memory-only demo and no encryption remain historical. Keep dates but direct everyone to \`IMPLEMENTATION_STATUS.md\`.
- **Preset semantics:** \`BUDGET_TEMPLATES.md\` plans are budget category/percentage allocations, **not page skins** and do not enter cash/loan balances.
- **Draft v0.4:** encrypted portable backup and edit work may exist on \`feature/v0.4-backup-recovery\`, but it is **unmerged and unverified** in this audit. Do not count it as a released feature.

## UX acceptance criteria (from owner intent)

1. A first-time user should understand **Bank → Accounts/Cards/Loans**, and separately **Budget Plan → Categories**, without reading a tutorial.
2. A loan can exist under a private lender even if no bank or deposit account has been created.
3. Every expense can be recorded from a specific cash account or credit card, with consistent balance and spending effect.
4. User should find their total cash, upcoming obligations, budget remainder and recent activity in under 10 seconds.
5. A saved budget template can be edited independently; original preset never mutates.
6. Clear offline/last-updated status: user never confuses manual records with a bank connection.
7. Error states never say “no accounts” while data is still loading.
8. Any irreversible delete/restore needs explicit confirmation and safe recoverability.
9. 30 different plans remain discoverable without forcing users through 30 separate cards.
10. Every screen works on small Android phones, large devices, font scaling, TalkBack and reduced motion.

## Product direction locked by this audit

- **Brand:** Tong Ledger by ParmTech. Public open source, Apache-2.0 code.
- **Platforms:** Flutter source portable; **Android only** is the release priority. No iOS/macOS/Linux builds yet; Windows optional later.
- **Connectivity:** Manual-first, offline-first, no mandatory signup or banking integration.
- **Currency:** AUD launch default; data types future-proof to ISO 4217, but do not promise working currency conversion until tested.
- **UI:** Distinctive premium navy/graphite and restrained champagne gold, with light theme and accessibility as first-class functionality.
- **Architecture:** Balanced journal and date-based reconciliation; domain independent of Flutter, storage, sync and OS.
- **Security:** No real financial data recommendation until recovery, device test and security release gates pass.
- **Release strategy:** Fit the essentials into a trusted, understandable first Android app; add pro modules incrementally.

## Handoff and next step

Read [MASTER_BLUEPRINT_V2.md](MASTER_BLUEPRINT_V2.md) for the canonical product requirements, [UX_INFORMATION_ARCHITECTURE_V2.md](UX_INFORMATION_ARCHITECTURE_V2.md) for exact screen flows, [FINANCIAL_DOMAIN_V2.md](FINANCIAL_DOMAIN_V2.md) for accounting/data integrity, and [ENGINEERING_ROADMAP_V2.md](ENGINEERING_ROADMAP_V2.md) for migration, rollout and test gates.

**Do not start major new app code before these specifications are reviewed against any open feature branches.** After review, implement the P0 accounting/storage backbone and slice-by-slice Android UX, not the entire wish list at once.
