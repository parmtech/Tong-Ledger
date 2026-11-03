> **ARCHIVED PRODUCT BRIEF — v0.1.** The audited [Master Blueprint v2](MASTER_BLUEPRINT_V2.md) is the current design and architecture source of truth. This historical document is kept for earlier decisions. Do not implement conflicting requirements from this file without the v2 decision log.

# Tong Ledger — A-to-Z Product & Engineering Blueprint

Version 0.1 • 3 November 2026 • Publisher: ParmTech • Product name: Tong Ledger • Public open-source repo • Android first

> THIS IS A SPECIFICATION, NOT A CLAIM OF COMPLETENESS. Do not solicit real customer financial data before storage encryption and release security review.

## A. Product definition and non-goals
A privacy-first, manual-first money manager helping individuals and families record their full financial picture, plan cash, control expenses, prepare for bills, understand card debt and loans, and make an editable budget in minutes. The first release is Android. Architecture is Flutter/Dart cross-platform but no iPhone/macOS/Linux binaries should be built now. Windows EXE optional only after Android foundation. No payments, bank login, bank account connection, investment orders, individualised financial advice or pretend live data in v1.

## B. Personas and use-cases
Teen, student, apprentice, employee on weekly/fortnightly payroll, shift worker, freelancer/sole trader, couple, young family, single parent, homeowner, independent lender debtor, international student, new arrival and retired household. Essential flows must take under 2 minutes for a simple setup, while advanced users can customise everything. Default AUD and Australia-first formats, configurable world currencies and locale.

## C. App structure
Phone bottom navigation: **Home | Money | Plan | Insights | More**. Money: **Institutions, Accounts, Cards, Loans, Assets, Income, Transactions**. Plan: **My Budgets, Templates, Goals, Bills, Upcoming**. Insights: **cash flow, savings rate, budget vs actual, liabilities, net worth, comparisons**. More: **profiles, tutorials, currencies, themes, accessibility, security, backups, data exports, about**. Tablet/desktop: navigation rail + responsive multi-column detail view. Each view has search, accessible empty states, loading/commit feedback, edit/undo where safe.

## D. First-run onboarding
1. Intro — privacy promise, local-only manual first, brand tour.
2. Language and display currency (AUD default); optional app lock. No mandatory signup.
3. Choose Start With Money / Choose Budget Plan / Explore Fictional Demo; can later switch.
4. Add bank by picker (e.g. Commonwealth Bank) OR type a custom institution; no online banking credentials.
5. Add N deposit accounts within institution (Salary, Savings, Household Spending), their opening balance **and as-of date**.
6. Add a linked credit card: optional last 4, A$ limit, owed, billing cycle, due date, payments.
7. Add independent loan OR bank loan: source, type, principal, balance, rate, instalment, frequency, next due; lender can be custom private company.
8. Add assets and their valuations with optional associated loan reference.
9. Add income source: employer or contract, net/gross, frequency, landing account, projected payday. Forecast does not become actual balance.
10. Choose 1 of 30 genuine budget presets, inspect allocations, copy, alter categories and save; or start from scratch.
11. Add first real transaction, choosing source account/card, category, date and optional note.
12. Explain balances, debts, safe-to-spend projection and net worth; show 2-min interactive tutorial and full Academy entry.

## E. Institution and account management
An Institution is a standalone organisational record (bank, lender, credit issuer, employer or broker); named and searchable with optional icon and country. Cash account belongs optionally to a bank, has unique ID, nickname, account kind (transaction/savings/cash/offset/other), currency, opening balance and reconcilable ledger. Multiple accounts per bank and multiple banks permitted. Bank-level summary aggregates only its linked assets, never double counts internal transfers. Archive is not delete; show an explicit safety check before deleting nonempty records. Users can customise category names and account nicknames.

## F. Credit cards
Credit card is a revolving liability with issuer, nickname, masked digits optional, credit limit, **outstanding owed**, available credit = limit minus owed, APR optional, statement closing and due dates, minimum repayment optional. Card purchases create expense and increase debt but do NOT debit bank cash. Card payments debit a cash account and reduce owed but create NO duplicate budget expense. Interest/fees create actual expense. Support refunds, reversals, overlimit, negative balances/credit balances, and payment reminders. All cards appear globally and under their institutions.

## G. Loans, including private lenders
A loan is separate from a bank account; lender/institution link is optional. Types: mortgage, car, personal, student, business, private, other. Fields: lender name, original principal, outstanding principal, rate type, APR/rate, repayment amount/frequency, next due, start/maturity, fees, collateral asset and custom notes. Interest/principal split recorded accurately or clearly marked estimated/pending; payment debit in cash, principal reduces debt and interest becomes expense. Handle early repayment, lump sum, refinance (linked new/old loan), paid-off state. Never assume a private lender offers a deposit account.

## H. Assets, valuations and net worth
Assets: property, vehicle, investments, business interest, physical valuables, cash equivalents and custom categories; optional owner share, currency, estimated value and dated valuation source. Net worth = eligible assets + cash balances – loan balances – card owed – other liabilities; avoid counting bank cash twice or subtracting secured loan twice. Optional manual investment account may be either included as asset OR cash ledger but not both. Label estimates and valuation timestamps.

## I. Income and sources
Sources: employment salary, gig, business, freelance, interest, dividends, pension, government support, rent, other. Fields: employer/payer, cadence daily/weekly/fortnightly/monthly/quarterly/yearly/irregular, take-home vs gross, expected next date and preferred receiving account. Expected inflows shown in forecast only. Manual actual deposit creates income transaction and credits selected account; duplicate detection and easy reconcile supported.

## J. Transactions and double-entry-safe money movement
Transaction types: income, cash expense, credit card purchase, bank-to-bank transfer, credit card repayment, loan repayment, interest, fee, refund, opening balance, adjustment. Each has stable id, UTC timestamp and local date, currency, amount integer minor units, optional category, payer/payee, account/card/loan IDs, notes/tags, audit trail and external import provenance. Transfer posts paired movement, no income/expense. Split expense allocated categories totals equal original. Correction may reverse but must never silently alter prior records. Avoid floating point and negative amount confusion; represent debit/credit explicitly.

## K. Budget planning engine
Multiple independent budget books (personal, household, car, holiday, small business). Planning period weekly, fortnightly, monthly, yearly or custom cycles, aligned to payday. Modes: zero-based, percent, fixed, envelope, rollover, hybrid, goal-first. Categories/subcategories customisable, assign weights or fixed sums and normalise for display. Actual category spending comes from transactions exactly once; card settlement does not double-spend. Expenses from multiple accounts can feed one budget or be explicitly excluded. User can roll unspent funds forward without changing actual cash. Warn on underfunded housing/debt/essential obligations.

### 30 real ready-made budget plans
There are six collections of five plans (30 total), each with real spending percentages and 100% allocation. See BUDGET_TEMPLATES.md for every category and exact allocation. Templates are **plans for budgeting**, not UI themes or loan records. Preview, clone, customise and save independent copies; source presets are immutable, and user changes never mutate other copies.

## L. Bills and subscriptions
Rent/mortgage, utilities, internet, insurance, rego, subscriptions, school fees and custom payments: amount, recurrence, payee, due date, funding account/card, reminder lead time, pausing, cancel/archive and payment confirmation. Upcoming scheduled bill is NOT automatically a posted payment. Month-end and leap-year date rules explicit. Annual bills can feed sinking funds.

## M. Goals and calculators
Emergency fund, car, house deposit, travel, education and custom goals with target/date, current balance, contribution cadence and what-if forecast. Debt avalanche/snowball simulations distinguish estimates from provider terms. Safe-to-spend = user-selected liquid balance minus reserved pending bills/goals/minimum obligations using explicitly stated assumptions; must never say safe-to-spend is guaranteed. Interactive charts and transparent formulas.

## N. Analytics
Cash/inflow/outflow, monthly recurring commitments, net worth history, debt balances, savings rate, budget performance, category/merchant trends, projected cash flow, period comparisons, export to PDF/CSV (future), chart accessibility summaries. Cash flow forecasts never presented as live bank balances; warning for outdated manually entered data.

## O. Luxury design system
Distinctive but restrained navy/graphite, champagne-gold accent, porcelain light mode and positive emerald; avoid gold-on-gold text and insufficient contrast. Calm large numerals with tabular digits, premium navigation, subtle animated gradients, round-corner cards, correct spacing, chart legibility, excellent empty states and responsive mobile/tablet/desktop shells. Light/dark/high contrast, dyslexia-friendly reading options, reduced motion, minimum 48dp targets, talkback, dynamic fonts and accessible colour indicators. See UX_DESIGN.md. The supplied concept artwork is illustrative, not a finished screenshot.

## P. Learning centre
Quick Start 2-minute tour, guided first transaction, full Academy lessons for banks/accounts, cards, loans, assets, pay cycles, budgets, predictions and privacy. Demo is isolated from actual data. Searchable FAQ and contextual Learn buttons. Tutorials can be skipped, resumed or reset and work offline.

## Q. Technical architecture
Flutter/Dart shared presentation+domain. Pure Dart money/accounting and budget engine, dependency-injected storage interface, local encrypted persistence when ready, platform adapters for secure storage, notifications and documents. Recommended Drift/SQLite persistence, Android Keystore-managed encryption secrets, and carefully reviewed crypto implementation. Currency amounts as integer minor units; database changes via migrations; never persist real finance data in unencrypted preferences. Repository-friendly boundaries support optional Windows later. See ARCHITECTURE.md and DATA_MODEL.md.

## R. Security and privacy
Local-first, no internet/bank credentials to start, screen privacy setting, lock with device auth, data-at-rest encryption and encrypted user-passphrase backups, no secrets in Git/logs, opt-in analytics only, self-serve deletion and export, malicious CSV/formula sanitisation, transaction corruption checks, clear data retention and threat model. If banking connections ever added, use compliant Australian CDR model/provider with consent and security controls; this is explicitly **not v1**. Keep financial statements informational, not advice.

## S. Offline, sync and future platforms
All core reads/writes must work offline. Sync is optional and must be encrypted, permissioned, conflict-aware, and never compromise ledger integrity. Flutter allows source sharing across Android/iOS/Windows/macOS/Linux; only Android debug/release builds first; Windows EXE optional later after Windows runner is available. No builds for iPhone, macOS or Linux at this milestone.

## T. Internationalisation
English initial, future Punjabi/Hindi support and other locales. AUD and locale-aware amount input, currency decimals and exchange reporting; never silently assume AUD if record uses another currency. Accessible monetary pronunciation. Support DST, timezone and varied pay cycles.

## U. Reliability and performance
Cold startup target to be measured, no blocking main isolate, responsive scrolling with 10k+ transactions, paged lists/search and image memory limits, battery-efficient reminders. Robust offline restore and schema migration; no data loss after backgrounding or rotation. Clear no-data vs loading vs error states. User controls animation. No unsupported performance claims until benchmarking.

## V. Quality and release tests
Golden calculations, transfers, card payment de-duplication, loan interest/principal, overlimit, refunds, date recurrences, 30 template percent totals, isolated demo data, app lock, backup round-trip, malicious files, accessibility at 200% text and TalkBack, multiple devices/Android versions, slow/low storage, external beta, privacy policy review and Google Play financial features declaration. Refer TEST_PLAN.md. Every UI action must have real behaviour before production.

## W. Google Play release
Select final package ID, signing key strategy and owner Play Console. Build Android App Bundle with release signing, target current API requirements at publication, configure Play Data Safety and financial features declarations, privacy policy, open-source notices, copyright/licensing, screenshots, listing, staged rollout and crash monitoring. No production release before encryption + migration + data export + tests. Trademark clearance for Tong Ledger pending.

## X. Open source operating model
Apache 2.0 as repository code license. CONTRIBUTING, SECURITY, issue/PR templates, dependency scanning, license audits, no copyrighted font redistribution, non-secret local fixtures only. Source may be publicly inspectable without exposing real users' data. Do not imply Apache automatically licenses third-party imagery or bank logos. Use generic icons until usage rights reviewed.

## Y. Milestones
M0 Charter, docs, templates, branding and repo setup. M1 Pure Dart finance domain/ledger + tests and usable demo shell. M2 Persistent encrypted storage, account/transaction add-edit flows, budgets, reminders and migration. M3 All 30 editable budgets, charts, goals, tutorial academy, exports and production UI. M4 Security review, accessibility, Play beta, signed AAB, rollout. Later: Windows desktop, other platforms, secure sync and optional bank integration. Android release gates take priority.

## Z. Definition of done and handoff
Every feature gets: acceptance criteria, unit/integration/widget tests, accessibility checks, negative cases, performance/privacy review, design parity, docs update and rollback plan. Update HANDOFF.md after each change with commit hashes, tested/not tested, blockers, exactly what remains. Never call the app complete merely because it launches. No guaranteed build until a real runner passes.
