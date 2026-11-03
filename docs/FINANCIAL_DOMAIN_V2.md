# Tong Ledger — Financial Domain and Data Integrity Contract v2

**Status:** Architecture and testing specification. The present v0.3 ledger is a valid learning prototype, **not** a complete audited double-entry financial journal. Code adoption must be staged and migration-tested.  
**Core rule:** Actual financial balances derive from posted ledger events; planned budgets, expected income, credit limits, asset estimates and scheduled bills never create real cash.

## 1. Financial model hierarchy

~~~text
Profile (v1: local owner; later optional household profile)
 ├─ Institution (bank / issuer / lender; independently named)
 │   ├─ Deposit account(s) with asset-ledger ID
 │   ├─ Credit card(s) with liability-ledger ID
 │   └─ Loan(s), if provider linked
 ├─ Standalone cash account, credit card or private-lender loan
 ├─ Asset valuations (car/property/investment) with dated ownership data
 ├─ Income sources (schedules only until posted)
 ├─ Journal: Transaction → 2+ balanced Postings → Ledger Accounts
 ├─ Budget Book(s) → Stable Category IDs → Budget Allocations
 ├─ Bills/Goals (planned, then optional linked posted transaction)
 └─ Audit, reconciliation, export metadata
~~~

An account's *role* (salary account, emergency savings, family expenses) is a user label independent of bank/ledger type. Institution membership may be changed without changing financial records. A private lender without a deposit account is normal.

## 2. Mandatory data model (target, not current code)

| Record | Identity & main fields | Integrity / consequences |
| --- | --- | --- |
| Profile | UUID, local owner, reporting currency, settings | No mandatory remote account; future household scope explicit |
| Institution | UUID, display name, kind, country, brand-icon reference optional | Can exist alone; provider links optional |
| MoneyLedger | UUID, kind = cash asset / card debt / loan debt / income / expense / equity / adjustment, currency, owner profile | No "floating" balance; totals from postings |
| CashAccount | UUID, MoneyLedger UUID, institution UUID?, nickname, subtype, opening as-of date, archived status | One source of actual account balance |
| CreditCard | UUID, MoneyLedger UUID, issuer UUID?, nickname, limit, statement owed, current owed from postings, due schedule, APR metadata | Available credit != cash; overlimit or credit balance representable |
| Loan | UUID, MoneyLedger UUID, lender UUID?, custom lender name, loan kind, original principal, outstanding, rate kind, schedule, next due, linked asset? | A loan can be independent of all banks |
| AssetValuation | UUID, category, amount, currency, owner share, valuedAt, optional source, linked liability IDs | Date and inclusion policy required; no double-count |
| IncomeSource | UUID, payer, kind, expected amount and frequency, net/gross, destination account?, next date | Forecast only |
| TransactionHeader | UUID, createdAt, effectiveDate, type, status, origin, category/merchant metadata, correctionOf? | Stable ID, scheduled != posted, full history |
| Posting | UUID, transaction UUID, ledger UUID, debit/credit direction, integer minor units, currency, category ID? | **Postings balance** per transaction/currency |
| Category | UUID, scoped type, parentId?, display label, archived, aliases | Rename does not break historical assignments |
| BudgetBook | UUID, profile/scope, income basis, period, cycle start, status, template origin UUID? | Planned only, independent records |
| BudgetLine | UUID, budget UUID, category UUID, planned integer amount, optional carryover | Sum checked against plan; versioned revisions |
| BillSchedule | UUID, payee, due rule, amount, funding account/card?, state, reminder, posted transaction? | Scheduling does not automatically post cash |
| Goal | UUID, target, date, linked account?, contribution rule | Distinct target from actual balance |
| Reconciliation | UUID, money ledger UUID, statement as-of, matched entries, adjustment reference | Audit trail and safe correction |
| BackupManifest | format version, schema version, key derivation, ciphertext metadata | Fail-closed, migration/recovery tested |

Implementation can use separate subtype tables or a sealed financial-account hierarchy. Preserve stable IDs and explicit scopes regardless of schema layout. Never store full card PAN, online banking credentials, ATM PINs or user-secret answers.

## 3. Numeric precision and currency

- Represent amounts as **integer minor units** and include explicit ISO currency code plus currency-specific exponent. AUD default uses 2 decimals; JPY 0, BHD 3 etc. Planned multi-currency UI/FX is post-v1 but model should avoid hidden global AUD assumptions.
- Parse exact decimal strings with strict bounds; don't convert financial data using binary floating-point to/from formatting.
- Account assets/liabilities use signed posting amounts but UI numbers should be labelled positive owed/available where appropriate.
- Enforce overflow, invalid decimals, negative import, zero-amount semantics and ratio/percentage limits before committing.
- Multi-currency transfers (future) require dated FX rate, source/provenance and explicit gain/loss rounding postings, not silent conversion at current rate.
- Audit metadata must keep original unrounded monetary entry and effective reporting-currency snapshot when needed.

## 4. Balanced journal — posting direction examples

Postings follow conventional debit/credit accounting; **sum of all debit minor units equals sum of all credit minor units per currency** for every posted transaction. Displayed account balances are projections from the appropriate ledger class. For illustration, debit/credit are accounting directions, not the user's bank statement column names.

| Event | Debit postings | Credit postings | User-facing consequence |
| --- | --- | --- | --- |
| Receive salary A$1,000 | Cash asset 1,000 | Salary income 1,000 | Cash +1,000; income +1,000 |
| Spend A$75 groceries via bank | Groceries expense 75 | Cash asset 75 | Cash -75, budget spent +75 |
| Move A$200 between two accounts | Destination cash 200 | Source cash 200 | Total cash unchanged; no income/expense |
| Purchase A$100 groceries with card | Groceries expense 100 | Card liability 100 | Card debt +100; cash unchanged |
| Pay A$100 card from salary account | Card liability 100 | Cash asset 100 | Cash -100; debt -100; **not another expense** |
| Repay loan A$600 (A$500 principal + A$100 interest) | Loan liability 500 + Interest expense 100 | Cash asset 600 | Cash -600, loan debt -500, expense +100 |
| Refund A$30 cash groceries | Cash asset 30 | Groceries expense 30 | Cash +30, category spent -30 |
| Card refund A$30 | Card liability 30 | Groceries expense 30 | Owed -30, category spent -30 |
| Open account with historical A$1,000 | Cash asset 1,000 | Opening equity 1,000 | Cash set to 1,000; **not salary** |
| Import card historically owed A$2,300 | Opening equity 2,300 | Card liability 2,300 | Card debt set 2,300, **not fresh spending** |

**Atomic unit:** transaction header plus all postings commit in one DB transaction, or none do. A scheduled bill is not automatically a posted transaction. When a correction is made, preserve the original and add explicit reversing/correcting postings with a reason. Never silently mutate posted financial meaning in place.

## 5. Opening balances and date-sensitive reconciliation

- Each manual opening balance has a **recorded date and "as-of" date**; import of earlier history needs clear duplicate prevention and historical correction rules.
- Every balance on Home or Money must show its information freshness (e.g. "updated manually 12 days ago"); not live bank data.
- A reconciliation compares app journal-derived balance with an external statement at a user-provided as-of date; any difference is a reviewed **adjustment transaction** (with reason), never a hidden overwrite.
- Transaction effective date (local calendar) and recorded-at timestamp (UTC) are separate; time zone changes should not change what month a salary belongs to.
- Out-of-order transactions are legal if posting dates are explicit. Reconciliation histories require deterministic snapshots.
- Bank/card/loan statements do not become assets or expenses themselves; they summarise existing postings.

## 6. Detailed account/card/loan rules

### Cash accounts
Account balance can go negative where overdrafts/adjustments allow. Transfers do not alter aggregate account assets. Account archiving does not delete transactions. Renaming a bank never changes account ownership or posting ledger ID.

### Credit cards
**Current owed** = outstanding liability after posted activity. **Statement owed** = balance on statement date; **minimum due** and **due date** may differ from current owed. **Available credit** = credit limit - current owed; show negative if over limit, and cap only when clearly described. Refunds may yield a credit balance (negative owed). Interest and fees are genuine expenses, card bill payments are not.

### Loans
Separate original principal, outstanding principal, interest accrued, fees and projected payoff. Fixed/variable interest rates and repayment cadence must be recorded as metadata; amortisation forecasts disclose assumptions. If split unknown, require manual split or mark pending; never silently classify full loan payment as expense. A linked property is an asset and the associated mortgage is still a separate liability; do not subtract twice.

### Assets
Gross current market estimate belongs to eligible asset valuation as-of, ownership percentage applied consistently (calculated with fixed-point rational). If an investment account's market value is used as the asset valuation, do **not** also add that same value in account cash. Total net worth = eligible cash + nonduplicative owned assets - card debt - loan principal - other recorded liabilities, with available coverage and freshness disclosure.

## 7. Budget attribution

- Every budget line is linked to a **stable Category UUID**; user-facing category name is a label, not key. Aliases after rename preserve history.
- Every posted expense or refund can be allocated into one or more split lines with categories, each sum exactly equal to the source transaction's expensed portion.
- Each BudgetBook defines its own reporting window, account/profile scope and category mapping. Distinguish budgets that intentionally overlap; never present summed categories across overlapping books as distinct total expenditure.
- Plan income, goal target and credit limit never modify journal balances.
- Category spending includes posted expenses, card purchases and interest/fees, plus eligible refunds; excludes account transfers, card payments and loan principal.
- Scheduled/unpaid expenses are tracked as forecast separately; bills only count actual after posting.
- Weekly/fortnightly cycles anchor to local dates; monthly cycles clamp end-of-month dates (e.g. 31 January → 28 February → 31 March) and preserve anchor logic without drift.
- Allow overallocated plan only after explicit warning and unchanged cash balance.

## 8. Safe-to-spend (future calculated estimate)

Start with user-selected liquid accounts (not card limits), subtract recorded/unposted pending bills due before next income, user-specified held funds and minimum known debt repayments. Exclude asset valuations, future income not yet received and uncertain forex. Show "Based on data last updated..." and calculation details. No guarantee. Do not ship forecast while required inputs are missing without clear incomplete-data marker.

## 9. Entity relationships and integrity gates

- Foreign keys: every posting must link to an existing ledger ID; every transaction/posting set balances; account institution relation optional but verified if present.
- One source of truth for each financial subtype: no duplicate cash and card representations of the same funds.
- Global ID uniqueness within scope; no blank names; custom lender allowed without bank ID.
- Import checks: supported schema/version/backup auth, record counts/size, dangling references, currency limits, duplicate IDs, illegal cycles, timestamps and amount overflow.
- Ownership/institution reassignment never changes historical posting IDs. Archive is non-destructive; delete semantics explicit.
- Enforce single logical writer and idempotency token for import/scheduled posting.
- Store transaction mutation as append-only correction/reversal activity with who/when/why.
- Use deterministic fixtures and property-based tests including random balanced posting sequences.

## 10. Suggested database boundaries (implementation choice pending review)

A robust option: encrypted SQLite/SQLCipher-style database behind pure Dart repository interfaces, with transaction headers, postings, institutions, subtype metadata, budget books and allocations, schedules, valuations and audit entries. Review platform compatibility, licensing and secure key handling before selecting a package; don't treat a package name as security certification.

**Migration:** old v0.3 AES-GCM JSON snapshot → decrypt+validate in memory → build new transactional schema in a staging DB → verify balancing and data counts → atomically activate new DB **without destroying original ciphertext** → retain recoverable safety copy through a defined upgrade window. Failed migration must leave original accessible.

## 11. Finance correctness acceptance examples

1. A$1,000 cash opening, A$200 transfer between accounts: consolidated cash remains A$1,000.
2. A$8,000 card limit, A$2,300 owed: A$5,700 available **credit**, not cash. A$100 card purchase and A$100 card repayment: category spent A$100 only.
3. Private-car-loan A$15,000; payment A$600 including A$100 interest reduces outstanding to A$14,500; booked expense A$100.
4. Mortgage A$200,000 against a separately valued property A$450,000: net worth includes property once and mortgage once, not property net equity **and** full loan subtraction again.
5. A loan lender without any deposit institution is accepted and globally listed.
6. Forecast weekly salary A$1,200 does not credit cash until posted.
7. Account opening balance as of 1 Nov and later dated transaction produce reproducible Nov 3 balance.
8. Category rename "Food" → "Groceries" preserves earlier spending attribution through UUID.
9. Attempt to remove an account with postings requires archive and retains all history.
10. A corrected transaction retains original and reversing postings; global journal always balances.
11. Import tampered or duplicated posting set rejects without editing original vault.
12. Monthly/fortnightly boundaries, DST and timezone changes preserve local cycle reporting.
13. Balance never includes available credit, future payslip, goal target or budget allocation.
14. Currency display and parsing round-trip without floating-point drift.

## 12. Definition of done for financial engine

Pure domain unit tests + property tests + schema migration tests + reconciliation examples + security/restore tests + real-device robustness. A consumer-facing transaction must explain effects on cash, debt and budget. No public-release claim until these gates are measured and documented.
