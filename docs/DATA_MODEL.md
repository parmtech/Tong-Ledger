# Data Model — Schema Contract

## Entity relationships
Institution 1-to-many CashAccount / CreditCard; Institution may be **null** for independent loans, accounts or cards. Loan has optional lenderInstitutionId and optional securedAssetId. IncomeSource has optional destinationAccountId. TransactionEntry refers to one or more ledger postings; BudgetBook owns user BudgetCategory allocations. TemplatePreset is immutable, cloned into BudgetBook. All entities use UUID-like stable IDs, user-profile scope and soft archive metadata.

| Entity | Essential fields | Validation |
| --- | --- | --- |
| Institution | id, kind, name, country, notes | name nonblank; custom allowed |
| CashAccount | id, institutionId?, nickname, type, currency, openingCents, openingAsOf | no accidental aggregate duplicate |
| CreditCard | id, issuerId?, nickname, limitCents, owedCents, dueDay?, APR? | limit >= 0; owed can exceed limit/negative credit |
| Loan | id, lenderId?, lenderName?, type, principalCents, balanceCents, rate?, instalmentCents?, frequency? | interest-only/variable-rate uncertainty labelled |
| Asset | id, kind, title, sharePct, valuationCents, valuedAt, linkedLoanId? | valuation date is mandatory; avoid double-count |
| IncomeSource | id, payerName, kind, amountCents, grossOrNet, cadence, destinationAccountId? | expected not posted |
| Transaction | id, type, sourceId?, destinationId?, amountCents, categoryId?, dateTime, memo, metadata | >0 amount, supported references |
| LedgerPosting | id, transactionId, ledgerId, signedCents, currency, categoryScope? | atomic journal, audit-safe |
| BudgetBook | id, title, dateRange, scope, currency, rolloverMode, allocations | allocations not actual balance |
| BudgetTemplate | stable id, collection, title, description, 100%-weight allocations | immutable and cloneable |
| Goal / Bill | id, title, amount, schedule/target, linked scope | forecast only until posted |

## Precision and direction
Money values stored as **signed 64-bit integer cents** for AUD unless ISO currency demands a different exponent. Core engine always takes a positive requested transaction amount and applies direction by action type, preserving a single transaction. Imports must convert decimal strings exactly, reject fractions of a cent, check overflow, and avoid ambiguous commas. Currency conversion is external rate data with version and timestamp; never silently re-denominate historical entries.

## Worked example (fictional)
Commonwealth Bank: Salary A$3,500, Savings A$5,500, Expenses A$900. Commonwealth credit card: A$8,000 limit, A$2,300 owed => available A$5,700. Private Lender: A$15,000 car loan (NOT in Commonwealth deposit accounts). If A$75 groceries paid from Expenses account, its balance becomes A$825. If A$100 purchased via card, card owed becomes A$2,400 but cash remains unchanged. If A$100 card bill payment made from Salary, Salary becomes A$3,400 and card owed A$2,300 without counting the payment as new expenditure.

## Integrity and migrations
Never delete a parent institution while live child accounts are linked without detach/migrate confirmation. Use database foreign keys and transactions, unique IDs and archived timestamps. Every schema migration requires forward-compatibility tests and encrypted backup restore validation. Use activity and reconciliation records for user-corrected balances; do not silently replace historic transaction amounts.
