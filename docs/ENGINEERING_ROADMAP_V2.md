# Tong Ledger — Engineering Architecture, Security and Execution Roadmap v2

**Baseline:** public \`parmtech/Tong-Ledger\`, Android-first Flutter/Dart v0.3 development foundation. The branch \`feature/v0.4-backup-recovery\` contains experimental unmerged work; **do not confuse that branch with the shipped app**.  
**Guiding sequence:** Correct finances → preserve data → make actions understandable → polish → beta/release → expand platforms.

## 1. Source architecture — isolate dependencies now

~~~text
apps/
  mobile_flutter/
    app_shell/             # routing, navigation, environment
    features/
      onboarding/
      home/
      institutions/
      accounts/
      cards/
      loans/
      assets/
      income/
      activity/
      budgets/
      bills/
      insights/
      help/
      settings/
    design_system/         # tokens + reusable accessible widgets
packages/
  finance_domain/          # PURE DART: Money, Journal, Reconciliation, Budget
  app_use_cases/           # Create, Edit, Archive, Post, Correct, Search
  persistence_contracts/   # Domain repository interfaces
  local_storage/           # SQLite/encryption/migrations; no UI references
  portable_backup/         # password KDF, encrypted format/restore validation
  platform_services/       # biometrics, notifications, docs, OS privacy
test/
  domain/
  property/
  use_cases/
  migrations/
  widgets/
  integration/
docs/
  MASTER_BLUEPRINT_V2.md
  UX_INFORMATION_ARCHITECTURE_V2.md
  FINANCIAL_DOMAIN_V2.md
  ENGINEERING_ROADMAP_V2.md
  BLUEPRINT_AUDIT_2026_11_03.md
~~~

**Important:** This is a *target layout*, not a demand to perform a disruptive monorepo rewrite on day one. Incrementally extract the existing \`lib/domain\`, \`lib/storage\`, \`lib/app\` code into interfaces and vertical features with running tests. Optimize for testability and clear data ownership, not number of folders.

Dependency direction: Flutter widgets → typed application actions → pure domain validators/calculations → repository contract → implementation adapter. No domain import of Flutter, Android or file picker. Navigation via typed routes/selected record ID, not implicit global mutable state. Platform features are adapters so later Windows/iOS/macOS/Linux use different native implementations without changing financial logic.

## 2. Code change policy and branching

- \`main\`: only reviewed, green-CI, documented changes; no secrets or real user data.
- Features use small branches, focused PR, acceptance tests and a reversible migration/release story.
- **Current v0.4 branch:** keep \`feature/v0.4-backup-recovery\` isolated; first audit its file-picker compatibility, KDF/password UX, atomic restore and missing device-key recovery; do not blindly merge.
- Prefer refactoring in vertical slices, e.g. **Post Cash Expense** with all layers rather than rewriting 30 screens before any works.
- Open-source issues and PRs use fictional data and avoid real institution logos until usage rights are checked.
- Update \`CHANGELOG.md\`, \`docs/IMPLEMENTATION_STATUS.md\`, \`docs/HANDOFF.md\` and affected tests every time.

## 3. Data persistence and recovery decision

**Production goal:** transactional encrypted local data store with durable journal and index/search. Recommended evaluation: SQLite with audited encryption mechanism such as SQLCipher through supported bindings, after licence/platform/performance review. The existing AES-256-GCM whole-file snapshot is a transitional developer implementation.

### Key and vault lifecycle
1. Generate high-entropy vault key using platform-secure entropy.
2. Keep key material in Android Keystore-backed secure storage when supported, respecting device restoration caveats and proper Android Auto Backup exclusions.
3. Build an independent **portable encrypted backup**, protected by a separate strong user secret with a documented, versioned KDF and authenticated encryption; never include the device key inside an unencrypted archive.
4. Export to a location selected via OS file picker, writing ciphertext only, with clear recovery reminder and non-sensitive success feedback.
5. Restore flow: choose backup → read size/version → unlock → authenticate → schema/ledger validation → preview counts → confirm replace/merge choice (v1 replacement only) → transactional import into *staging* → verify → activate → retain rollback safety copy → reload UI.
6. **Missing OS key with existing vault file:** do not silently overwrite or reset. Provide explicit recovery from portable backup via a separately designed, heavily tested safe re-initialisation flow that preserves the inaccessible original file for forensic recovery until the user confirms.
7. Wrong password, tampered import, interrupted write, storage full, process kill and old schema all fail closed without corrupting original records.
8. Device migration/restore and password forgetting require plain-language documentation. **No claim of guaranteed recovery without a readable backup and password.**

### Data lifecycle
Create → edit limited metadata → post actual transaction → reconcile → append correction/reversal → archive → user-confirmed export/delete. Define purge rules without affecting unrelated linked history. Keep audit logs redacted, not full transaction details in crash telemetry.

## 4. Security and privacy release guardrails

**Before requesting real financial details**:
- On-device lock/biometrics and lock-timeout policy; screenshot and app-switcher privacy mode.
- Signed/authenticated storage and backups; key invalidation/recovery tests, zero secrets printed in logs.
- Versioned migration with rollback, corruption and partial-write simulations.
- Permissions review: no unnecessary Contacts/SMS/location/banking credentials. OS file picker restricted to user-initiated backup flow.
- Data Safety and privacy policy accurately reflect any networking/crash reports; offline-first means core can work with network completely off.
- SAST, dependency alerts, SBOM where practical, licence notices, secret scanning and public vulnerability reporting.
- External security review before broad public launch. Application is an organiser, not a licensed bank or personalised finance adviser.

**Risk note:** source availability through open-source licensing does not automatically make a product secure; it enables review. Do not label a debug APK "secure enough for real money" solely because AES-GCM is used.

## 5. Long-term platform and scale strategy

| Layer | Android now | Later Windows/iOS/macOS/Linux | Cloud/household later |
| --- | --- | --- | --- |
| Finance domain | Pure Dart journal/budget | Reuse unchanged | Reuse unchanged |
| Database | Encrypted local store + migration | Platform adapter with OS keychain | Replicated event IDs/conflict detection; server not source of unverified financial truth |
| UI | Compact touch-first Material-based luxury design | Responsive split views, keyboard, window resizing, accessibility | Permission-controlled household views |
| Notifications | Android local reminders | Per-platform notification adapters | Opt-in remote reminders only |
| Files | Android document picker | Per-platform secure file pickers | End-to-end encrypted backup transport only |
| Auth | Local PIN/device biometrics, no signup | Platform secure storage | Optional account/consent, separate from financial data |
| CI | Flutter analyze/test, Android debug + signed AAB later | Separate matrix with Windows/macOS runners and signing | Independent API/server tests |

**Future-proof data contracts now:** stable UUIDs, ISO currency codes, effective dates and revision IDs, separate profiles and ownership, explicit backup schema, deterministic transaction IDs. Do **not** build cloud syncing, collaboration or AI in the v1 critical path.

### Future optional cloud sync — constraints
- End-to-end encryption, device identity, permissions, household roles, revocation, offline conflict reconciliation, event ordering, idempotency and detailed threat review.
- Never copy personal finance entries into public issues or an AI training endpoint.
- "Sync enabled" must remain an opt-in user action and permit complete local use without it.
- Any Australian banking CDR integration requires appropriate legal/provider/security due diligence. Never ask for banking passwords.

## 6. Prioritised engineering roadmap — vertical slices

### Gate 0 — Audit approval and product architecture freeze (NOW)
- Canonical v2 blueprint, UX flow and accounting rules merged to GitHub with owner requirements.
- Freeze navigation, naming glossary, brand tokens, MVP scope and migration strategy.
- Map current modules to future architecture without rewriting the app blindly.
- Document every P0/P1/P2 gap with acceptance tests and design mockups/wireframes.
- No new code merged into main until at least technical consequences of the audit are reviewed.

### Gate 1 — P0 financial correctness and robust state
- Implement balanced journal postings as additive domain engine with property tests.
- Introduce stable IDs, transaction states, date/as-of semantics, category IDs, corrections/reversals and relationship validation.
- Migrate current v0.3 snapshot through a staging copy; no silent destructive overwrite.
- Add account/card/loan reconciliation and derived-balance explanations.
- **Done:** random transaction sequences balance; all known examples pass; legacy data survives tested upgrade/rollback.

### Gate 2 — P0 safe storage, portable backup and recovery
- Review/rework ongoing v0.4 backup branch against the v2 security rules.
- Implement encrypted transactional persistence or define a safe phased bridge with backup guarantees and credible limits.
- Add device and portable key lifecycle, self-contained encrypted backups, export/import test, verified recovery from lost key and interrupted migration without losing old file.
- Add app lock/privacy options and on-device test instructions.
- **Done:** restored test fixtures across devices/versions, wrong-password/tamper and low-storage tests pass; no P0 data loss.

### Gate 3 — P1 beginner navigation and critical flows
- Build reusable app shell with Home/Money/Budget/Activity/Insights tabs + Settings/Help.
- Replace generic add sheet with clear task-specific forms, contextual help and named account/card selection.
- Make bank group/account/card/private-loan setup coherent; create/edit/archive with safe effects.
- Transaction preview and correction flow; Activity search and filter.
- **Done:** novice test tasks reachable in 1–3 taps from relevant page, no false empty/loading states.

### Gate 4 — P1 budgeting and obligations
- 30 templates picker with six collections, short recommendations and accurate preview.
- Budget category IDs, split allocations, stable reclassification, planned vs actual progress, unallocated/overallocated warnings.
- Basic bill schedule/due state, goals and weekly/fortnightly planner.
- **Done:** no double-counting across card payment, loan principal, transfers, category renames and overlapping budgets.

### Gate 5 — P1 luxury design, learning and accessibility
- Implement tokenised light/dark theme, premium branded components, accessible financial cards, context-rich empty states.
- Responsive phone/tablet layout, TalkBack, 200% text, reduced motion, right-to-left design readiness.
- Quick Start, eight learning lessons and safe fictional demo environment; measure onboarding.
- **Done:** UX pilot tasks, accessibility and performance tests pass on reference Android devices.

### Gate 6 — Android release preparation
- Pin native Android config / package ID, set real semver and application signing, CI artefact naming, dependency/security scans.
- Privacy policy, open-source attribution, bank-logo/licence audit, Play financial features and Data Safety declarations, trademark/name clearance.
- Produce signed AAB with separate upload keystore, use internal then closed beta, staged rollout and safe rollback.
- **Done:** passed release checklist, Play requirements and verified install/update/recovery of test data.

### After release — optional expansion
- Additional advanced reporting, receipt reading, taxes estimates and envelope rollover.
- Windows EXE after runner/signing and desktop UX tests; iOS/macOS/Linux builds later.
- Optional secure household sharing, synchronisation, compliant bank integration, AI helpers.
- Never let a later platform rewrite core accounting rules.

## 7. Test matrix and quality bar

| Layer | Automated | Real-world / manual |
| --- | --- | --- |
| Money & journal | Exact minor units, balanced postings, duplicates, reversals, property-based sequences | Sample account statement comparison |
| Loans/cards | Payment split, statement due vs owed, overlimit, refunds, fixed/variable rate uncertainty | Fictional lender/card schedules |
| Budget | 30 presets, independent edits, stable categories, cycle dates, missed/late income | Novice template picker study |
| Persistence | Migration N-1/N, corrupt/tampered import, low-storage injection, idempotency | Force-close, device upgrade and restore from file |
| Security | Authenticated encryption, wrong passphrase, no secret logging, dependency scan | New-device and invalidated-key recovery, external audit |
| UX | Navigation/widget/golden tests, loading/empty/error, long text | Small phone/tablet, TalkBack, 200% font, reduced motion |
| Release | Android AAB build, signing check, package ID, Play policy static checks | Internal/closed beta, staged rollout and update/rollback |

Targets should be **measured** rather than promised: startup, cold restore, save latency, 10k+ transactions search, scroll smoothness, battery impact of reminders and encrypted DB sizes. Record device models and CI version in test evidence.

## 8. Developer roles / handoff workflow

For every PR:
1. Read v2 blueprint, audit and architecture; check existing open PR/branches.
2. State scope, financial impact, screen UX states and backward-compatibility risk.
3. Implement pure domain tests first, use-case tests second, widgets last for core operations.
4. No unreviewed real financial fixtures, no secrets/logo images without rights.
5. Verify \`flutter analyze\`, \`flutter test\`, Android build and integration where applicable.
6. Update design docs, \`CHANGELOG\`, \`IMPLEMENTATION_STATUS\`, \`HANDOFF\`, include exact commit and workflow run.
7. Keep unverified items explicit. Release claims must cite tested signed binary, not a successful debug build.

## 9. Decision log (current recommendations)

| Decision | Why | Status |
| --- | --- | --- |
| Flutter/Dart shared source; Android first | Fits eventual cross-platform aim without other builds now | Confirmed by product direction |
| 5 task-based tabs + separate Settings | Makes transactions accessible, Home simple | Proposed UX v2 — review before UI implementation |
| Balanced posting journal | Financial correctness, recoverable history | Required P0, not yet implemented |
| Transactional encrypted DB with migration | Reliable edits and large history | Required P0, evaluate implementation/libraries |
| Versioned encrypted portable backup | Independent recovery after device replacement | Required P0, validate experimental v0.4 branch |
| 30 genuine budget allocations as immutable presets | Direct match to user requirements | Confirmed |
| No mandatory cloud sync/AI/bank integration | Privacy, low launch complexity | Confirmed |
| No production release until recovery + accessibility tests | Finance app trust threshold | Required release gate |
| UI design tokens and measured contrast | Premium and readable, not decorative clutter | Proposed UX v2 |
| Future scope behind interfaces | Add desktop/iOS/sync without core rewrite | Required architectural boundary |

## 10. Immediate implementation handoff

**Next coding PR should not blindly continue the v0.4 backup work.** First reconcile that experimental branch with the new recovery/key requirements, choose the safest migration path, and implement small verified slices. Maintain current working v0.3 source on main as fallback until v2 migration tests are green. Any data-destructive operation must have a reviewed recovery plan and clear on-screen explanation.

**Production status remains unchanged:** v0.3 is a development debug build, not a complete secure personal finance application. This roadmap intentionally protects users from a rushed release.
