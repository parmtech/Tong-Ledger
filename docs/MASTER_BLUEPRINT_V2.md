# TONG LEDGER — Master Product Blueprint v2

**Canonical plan date:** 2026-11-03  
**Project:** Tong Ledger (by ParmTech)  
**Licence:** Apache-2.0 code, subject to separate asset rights.  
**Target:** Android first; Flutter/Dart shared foundations for later Windows, iOS, macOS, Linux.  
**Status:** **Product specification and implementation contract, NOT production feature claim.**  
**Companion documents:** [Audit & flaws](BLUEPRINT_AUDIT_2026_11_03.md) · [Experience design](UX_INFORMATION_ARCHITECTURE_V2.md) · [Financial engine](FINANCIAL_DOMAIN_V2.md) · [Engineering roadmap](ENGINEERING_ROADMAP_V2.md)

## 1. The product in one sentence

A gorgeous but **easy-to-understand, private, manual-first money manager** where anyone can organise banks/accounts/cards/loans/assets/income, record what actually happened, and turn 30 real budget-plan examples into a personal, editable spending plan.

**Promise:** "Your money. Your rules." Everything is explainable and controllable; no bank login is needed to start. Financial figures have dates and sources. The app never implies that unconnected manual figures are live bank balances.

## 2. Non-negotiable design principles

1. **Clarity over visual spectacle:** first show the answer, then details and advanced fields on demand.
2. **Human financial language:** "Money in accounts", "Credit card owed", "Upcoming bills", "Planned budget", "Spent so far". Explain "net worth" with an optional info control.
3. **One source of financial truth:** ledger postings determine actual balances; income forecasts and budgets do not.
4. **Institution != account != liability != budget:** bank is a relationship/container; a private lender need not have deposit accounts.
5. **Progressive onboarding:** users may start with one bank and one account; no 12-screen forced questionnaire.
6. **Trustworthy privacy:** offline-first, transparent local storage, encrypted backups, no bank password collection. No cloud dependency in core workflows.
7. **Flexible but constrained:** custom types/categories and templates; validation protects accidental destructive actions.
8. **Accessible luxury:** dark and light themes, high contrast, gentle motion and clear large-number typography.
9. **Portable architecture:** domain/models unconnected to Flutter widgets or platform file pickers; future sync needs no ledger rewrite.
10. **Honest release status:** debug APK is not a certified/recoverable banking app.

## 3. User groups and default tasks

| User | First desired task | Best setup | Later needs |
| --- | --- | --- | --- |
| Teen / student | Track allowance, rent and saving | "Simple budget" starting template | Goals and category reminders |
| Employee | Salary, accounts, cards, expenses | Bank + salary account + quick budget | Fortnightly pay-cycle and bills |
| Couple/family | Household spending across accounts | Household budget and several accounts | Shared profiles later |
| Freelancer/sole trader | Irregular pay and taxes | Variable-income preset | Tax reserve and income reconciliation |
| Homeowner | Mortgage, property, bills, cards | Account + independent mortgage and asset | Property valuation, amortisation |
| Private lender borrower | Track car loan not attached to a bank | Add Loan → Other Lender | Payment schedule and refinance |
| New arrival / international student | Simple expenses in AUD | Essentials starter, editable categories | Multilingual help |

**Design for novices first, allow expert mode without hiding core balances.**

## 4. Terminology contract — use one name per concept

- **Institution**: a bank, card issuer or lender/company. Custom names allowed. Avoid treating an employer as a bank.
- **Account**: a deposit/cash/offset/etc. account with money (asset).
- **Credit card**: revolving amount owed (liability); available credit is borrowing capacity, **not cash**.
- **Loan**: debt from a bank or independent private company/person; all appear in the global Loans view.
- **Asset**: an owned thing with dated estimated value, different from current bank cash.
- **Income source**: a schedule or payer relationship. Expected income is not a deposit.
- **Transaction**: a posted or reconciled actual money movement; pending/scheduled entries are not posted.
- **Budget plan**: a future spending allocation with a defined period and income basis.
- **Budget template**: a real ready-made distribution across categories, clonable and editable; NOT a screen theme.
- **Balance**: derived from opening/reconciliation journal and actual posted transactions.
- **Net worth**: eligible assets plus current cash minus liabilities, with as-of warnings.
- **Available to budget**: a calculation from selected planning income, not a bank account balance.

## 5. Launch information architecture

**Primary navigation (five destinations):**
1. **Home** — overview, what matters today, next actions.
2. **Money** — institution groups and segments for Accounts, Credit Cards, Loans, Assets, Income Sources.
3. **Budget** — My Plans, 30 Templates, Categories, Goals, Bills (later modules visibly marked).
4. **Activity** — all actual transactions, search, filter, detail, transfer, correct/reconcile.
5. **Insights** — graphs, trends, net-worth history and forecasts with clear estimate labels.

**Global access:** top-right profile/settings/help; one floating or prominent **+ Add** with labelled actions; export/import in Settings → Data & Backup. Do not overload the bottom bar with an uninformative "More" tab.

**Design contract:** menus never show misleading "coming soon" buttons as if operational; unfinished modules may be hidden until test-ready or clearly labelled in an educational preview.

## 6. First-run in fewer steps, details optional

**Simple path (target 2–3 minutes, measured by usability testing):**
1. Welcome with **Start manually**, **Choose a budget first**, **Explore demo**.
2. Choose AUD (default) and privacy/lock preference (skip allowed).
3. Add an institution and one account with balance **as of date** (or choose **Start without a bank** for cash/loan users).
4. Show a useful Home with "Add your first expense", "Add another account" and "Choose a budget plan" cards.
5. Contextual 30-second in-app explanation of "planned vs actual"; Quick Start remains resumable.

**Guided path:** add multiple accounts, card, bank/third-party loan, assets, income schedule, template, transaction. Each can be skipped. Never force users to create a loan or card they do not have.

**Advanced path:** manual currency, account type, note, bank grouping, dates, min payment, interest, tax reserve and custom categories.

**Academy:** 2-minute Quick Start + eight self-paced lessons with play-with-demo mode, not seven long modals before Home.

## 7. Precise product feature contracts

### 7.1 Institutions and money accounts
- Search/select common AU banks or enter any custom institution/lender name and country.
- Institution overview shows linked accounts, cards and loans with relation badges, not an opaque combined "balance".
- Multiple salary/savings/household accounts per bank, separate nicknames and opening balances dated as-of.
- Independent cash account allowed if user has no bank setup yet.
- Create, rename, reorder, archive, reassign to different institution, view ledger and reconcile each account.
- Bank profile can be renamed without editing financial history; delete requires no linked active records or safe detach.
- Do not show full account identifiers by default; last-four and alias only if opted in.

### 7.2 Credit cards
- Link to issuer or custom independent issuer. Multiple cards supported.
- Current owed, credit limit, remaining credit, statement balance, due date, minimum repayment, optional APR and billing cycle.
- Card purchase: posted expense + increases liability, no immediate cash debit.
- Card payment: reduces bank cash and card debt, no duplicate expense.
- Refund, fee, interest, statement reconciliation, over-limit and credit-balance scenarios.
- Clearly differentiate **available credit** from **available funds**.

### 7.3 Loans
- Type: Home, Car, Personal, Student, Business, Private, Other.
- Bank or non-bank lender relationship optional; lender name required for independent loans.
- Track original, outstanding, rate type, interest and fee estimate, payment frequency, next due and settlement state.
- Principal, interest and fee components separate on repayment. Unknown interest split cannot be presented as accurate.
- Extra payments, restructure/refinance and asset link have explicit financial meaning.
- All loan records accessible under global Loans and shown in institution view only when associated.

### 7.4 Assets and estimated wealth
- Categories: home, vehicle, investment, business equity, valuables, other.
- Ownership share, value, currency, valuation date, custom note and optional associated debt.
- Avoid double-counting any financial account represented as both cash and investment asset.
- Net-worth cards display "**Estimated**" and date/coverage (e.g. "last updated 18 days ago").

### 7.5 Income and transactions
- Employment, business, freelance, rent, interest, government, investment and custom income sources.
- Weekly, fortnightly, monthly, quarterly, annual, irregular schedules. Gross/net clarified.
- Forecast never automatically becomes received cash. When income actually arrives, choose target account.
- Expense posting chooses exact account or credit card, category, date, amount and optional merchant/notes.
- Transfers choose both accounts. Refunds and reversals link to original; split transactions need stable category IDs.
- Every money-changing action previews "what will change" before confirmation.
- Activity list can search, filter, edit categorisation, correct/reverse and reconcile with statement.

### 7.6 Budget engine — 30 real ready-made plans
- Six collections × five presets in \`BUDGET_TEMPLATES.md\`; each 100% and fully clonable.
- Guided picker asks **Who is this for?**, **What's your pay cycle?**, **Main goal?**; suggests 3 suitable presets without implying professional financial advice.
- Preview shows income basis, allocated amounts, editable categories and any uncovered actual obligations.
- Save user-owned copy with stable IDs, period, start date, custom categories, amount allocations and optional rollover.
- Track **actual** category spending from posted entries exactly once, using stable category IDs (not mutable strings).
- Support multiple budgets (Personal, Household, Holiday, Car, etc) without accidentally counting an expense twice in one report.
- Missing bill obligations are flagged as "not yet included", not silently ignored.

### 7.7 Bills, subscriptions, goals
- Due date, recurrence, payee, amount, category and expected payment source; reminder-only until marked paid.
- Monthly and annual schedules respect month ends, holidays and user time zone; next due vs paid status clear.
- Goals have target, deadline, recurring allocation, current contribution and scenario forecast. Goals do not alter cash unless a real transfer is posted.
- Debt payoff scenarios explicitly label assumptions and estimated interest.

### 7.8 Insights and forecasts
- Real vs planned vs estimated must be distinguishable in every chart.
- Cash flow, budget vs actual, expected upcoming bills, debt trend, assets and net worth.
- Charts must expose a text equivalent, time filters, income vs spending subtotals and exportable definitions.
- Safe-to-spend is an optional estimate with included account scope and dated assumptions; never guarantee it.

## 8. Personalisation without complexity

Launch personalisation: hide/show cards, currency display format (AUD first), home card order, category labels, dark/light/system theme, reduced motion, notification preferences, tutorial reset, privacy preview, account grouping. **Do not** build a fully freeform drag-and-drop dashboard as launch blocker; defer it until the default experience is stable and user-tested. Advanced settings stay behind one optional section.

## 9. Reliability and offline trust

- No account needed to use the app; manual data remains available without connectivity.
- Every save indicates **Saving → Saved** or **Couldn't save; previous data kept**. Never display false success.
- Last-updated dates and stale-balance indicators appear where trust depends on recency.
- Import, restore, migration, correction and other destructive changes have previews and tested rollback.
- No silent schema conversion or data loss. Restore of old backups is tested with golden fixtures.
- Clear data lifecycle: create, edit, archive, delete/export/recover; consent for any future sync or analytics.

## 10. Technical and security contract

See [Financial Domain v2](FINANCIAL_DOMAIN_V2.md) for postings, balances, accounts, precision, time and record correction. See [Engineering Roadmap v2](ENGINEERING_ROADMAP_V2.md) for modules, encrypted database, backups, release gates, project structure and future expansion. Core domain uses pure Dart and stable use cases; UI never edits JSON records directly. OS APIs accessed through adapters.

App-lock/backup/recovery are not secondary polish: they are **P0 trust features** before a consumer personal-finance release. Code and sample APKs must make their unverified beta status visible until passing real-device tests.

## 11. Visual identity

Premium rather than cluttered: obsidian/navy, restrained champagne, porcelain light mode, clear contrast, large tabular financial numbers, thoughtful spacing and polished microinteractions. No decorative busy 3D effects behind financial figures. Dedicated design tokens, component states, responsive layouts and accessibility requirements are locked in [UX Information Architecture v2](UX_INFORMATION_ARCHITECTURE_V2.md).

## 12. Release scope

**Android v1 public MVP must reliably do:** manual institutions, linked accounts/cards/loans, assets/income, cash/card/loan ledger, multiple editable budgets including 30 presets, activity search, essential bills, encrypted local persistence, secure backup+restore and guided onboarding. Must have acceptable Android device/QA test results and accessible premium UX.

**After Android launch:** advanced reports, flexible envelopes/rollovers, receipt recognition, cloud household sync, wider currencies with exchange sources, AI helpers and optional compliant bank integration. Android-first **source** remains portable but neither iPhone nor desktop release is a prerequisite.

## 13. Non-goals and scope boundaries

Not a bank; no fund custody, payments, brokerage, tax filing or professional financial advice; no requirement for live financial integrations. Avoid mandatory AI, advertisements, affiliate links, cloud accounts, generic financial "scores", intrusive notifications and unapproved access to device banking credentials.

## 14. Release acceptance summary

Before production:
- Balanced accounting and bank/card/loan integrity property tests pass.
- Real data survives app restarts, crash/low-storage tests, schema upgrades and secure device-to-device restore.
- No missing-key overwrite, no plaintext finance log/backup, no secrets in public source.
- Screen-by-screen UX passes usability tasks and TalkBack, 200% font, small phone/tablet and dark/light contrast.
- App metadata, privacy policy, Play financial features declaration, Android signing, package ID and trademark/asset rights are cleared.
- Internal/closed Play testing with explicitly fictional data and documented outcomes.
- \`README\`, \`IMPLEMENTATION_STATUS\`, \`CHANGELOG\`, \`HANDOFF\` and release notes match the binary actually delivered.

## 15. How to use this v2 blueprint

This file supersedes the **product/UX and architecture decisions** of the older [v0.1 master blueprint](MASTER_BLUEPRINT.md), which remains as historical background. See the audit report for rationale. Current source code still represents v0.3 and may differ from this v2 target. **Do not claim a v2 requirement is implemented until its tests and CI pass.**
