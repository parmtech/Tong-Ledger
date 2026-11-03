# Tong Ledger v0.3 — Personal Budget Engine

**Status:** Development branch. Android-first. Do not treat a budget as actual available money.

## 1. Actual ready-made plans, not page templates
The app ships 30 immutable plan presets across 6 groups. Selecting a preset opens a **new personal copy** with its own unique ID. No source template record or another user's copy changes. Each personal plan may have a different income amount, title, weekly/fortnightly/monthly/yearly cycle, start date, category names, and AUD allocation amounts.

## 2. Core model
- `BudgetPlan`: ID, name, optional source preset ID, period, cycle anchor, planned income in integer cents, editable category allocations in integer cents.
- `BudgetAllocation`: category label + planned amount in integer cents.
- `FinanceBook.budgets`: independent list of zero or more personal budgets.
- Users may create a blank budget, clone from a preset, duplicate an existing plan, edit a plan or delete just the plan.
- Validation: distinct category names case-insensitively, non-negative amounts, max 100 categories, budget name required, AUD amount precision to 2 decimal places. Overallocated plans are allowed only with explicit on-screen confirmation.

## 3. Persistence and migration
Plans are stored in the existing encrypted AES-GCM local snapshot (same account-independent encrypted payload). The version 1 codec now optionally reads `budgets`; previously stored v0.2 vaults have no such field, which decodes safely to an empty list, preserving banks/accounts/cards/loans/transactions. Decode validates every saved budget; malformed content fails closed.

## 4. Budget vs actual rules
Budget category amounts are forecasts/planning allocations, not account balances. Choosing a plan must never create income or debit/credit cash. Current actual spending is calculated only from posted transaction types:
- Cash expense and credit card purchase: count once in category.
- Card/cash refund: reduces category spending.
- Loan repayment: count **interest**, not repaid principal (only if it has a matching spending category).
- Transfers, card repayments, cash deposits/income, and opening balances: NOT expenses.
- Only activity in the budget's current calendar cycle is displayed; unmatched transactions do not get magically mapped to a category.

## 5. Pay-cycle calculations
Weekly and fortnightly use fixed 7/14-day cycles anchored to the date chosen by the user. Monthly/yearly use calendar-date anchors, and shorter months clamp safely (31 January → 28 February → 31 March). Financial calculations use integer cents. The UI uses local calendar days; per-profile timezone history remains a follow-up requirement.

## 6. UX screens
- **Plans:** custom budget creation, six collections of five presets, existing editable budgets.
- **Template preview:** view 100% allocation categories on fictional A$4,000 and create an independent personal budget from the preset.
- **Editor:** title, income, frequency, cycle start date, add/remove/rename categories, set amount in dollars, live allocated/unallocated preview and over-budget warning.
- **Saved budget:** expand per-category spending-versus-plan bars; Edit, Duplicate and Delete (with confirmation). No transaction is deleted when deleting a budget.
- User changes pass through the existing validated encrypted store and do not visually commit when persistence fails.

## 7. Future scope, not implemented yet
- Automatically map categories using merchant rules and category suggestions.
- Custom category hierarchy, multi-currency budgets, pay-cycle conversions, rollover envelopes and household permissioned sharing.
- Receipt imports, recurring bills, reconciliation and account-scoped budgets.
- Backup and recovery. Before real financial use, secure backup/restore, on-device tests and independent security review are required.

## 8. Acceptance tests
Template copied independently; saved user budget round-trip; v0.2 vault migration; 100% template cents sum; category negative/duplicate validation; money transfer and card repayment excluded; category refund and loan interest appropriately counted; monthly 31st/fortnightly cycle boundaries; UI can create a personal budget in a fake store. GitHub CI must pass analyze, tests and Android debug build before merge. A green CI is not a Play Store security certification.
