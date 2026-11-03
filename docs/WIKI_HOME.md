<p align="center"><img src="../assets/brand/mark.svg" width="120" alt="Tong Ledger gold monogram"/></p>
<h1 align="center">TONG LEDGER — WIKI</h1>
<p align="center"><strong>Every account. Every budget. Your rules.</strong></p>
<p align="center">A luxury-inspired, open-source and offline-first money management app by <strong>ParmTech</strong>.</p>

---

> **Android first** · **Flutter/Dart shared source** · **Manual bank/account management** · **30 ready-made budget plans** · **Apache-2.0**

## Start here

| Explore | What you will find |
| --- | --- |
| 🚀 [Product tour](#product-tour) | Quick introduction to the experience |
| 🏦 [Banks, accounts, cards and loans](#the-way-money-is-organised) | How real-world finances are represented |
| 📊 [Ready-made budget planner](BUDGET_TEMPLATES.md) | 30 editable actual budgeting allocation plans |
| 🧭 [Quick-start tutorial](ONBOARDING_TUTORIALS.md) | Step-by-step first-use guide |
| 🧠 [Complete A-to-Z blueprint](MASTER_BLUEPRINT.md) | Product architecture, users, financial rules, delivery |
| 🏗️ [Engineering architecture](ARCHITECTURE.md) | Flutter modules, models, boundaries |
| 🔐 [Security and privacy](SECURITY_PRIVACY.md) | Planned protection, current demo limitations |
| 🎨 [Luxury UI and UX](UX_DESIGN.md) | Design direction, accessibility, navigation |
| ✅ [Tests and release gates](TEST_PLAN.md) | What must pass before Android release |
| 🗺️ [Roadmap](ROADMAP.md) | What ships first and what comes later |
| 🔧 [Implementation status](IMPLEMENTATION_STATUS.md) | What is already committed vs remaining |

## Product tour

Tong Ledger brings **your complete financial picture** into one clear, elegant dashboard. It is not a banking login app. You **manually** choose or name each institution, then track your accounts, credit cards, lenders, income, assets, expenses, budgets, bills and goals, even with no internet connection.

### The way money is organised

1. Add Commonwealth Bank, another known bank or any custom institution.
2. Under that bank, manually add Salary, Savings, Household Spending and any extra accounts.
3. Add Visa/Mastercard or a custom credit card under its issuer, storing limit, amount owed and due date — **available credit is not cash**.
4. Add a **car loan from a private finance company**, a bank mortgage or another type of loan. Lenders may be independent of a bank.
5. Add dated property/vehicle/investment valuations to estimate net worth without double-counting debt.
6. Add salary, business, freelance or irregular income sources and select the account receiving actual payments.
7. Record cash expenses, card purchases, deposits and loan/card repayments against the proper source account. Transfers never inflate spending.
8. Choose a budget template, preview its percentages, modify allocations and save as an independent personal budget (editing persistence is a planned feature, not yet implemented).

## Budget plans, not visual skins

Choose from **Students & Youth**, **Salary & Careers**, **Couples & Families**, **Variable Income**, **Goals & Debt**, and **Lifestyle & Milestones** — **five fully specified plans in each group**. The underlying seed-data map always totals 100%. You can later override percentages, fixed amounts, periods, category titles and linked accounts. No financial information is created merely by choosing a budget.

[See all 30 complete plans](BUDGET_TEMPLATES.md)

## Luxury experience

Refined navy-black backgrounds, champagne-gold detailing, clear numerical hierarchy, subtle motion, purposeful cards and light/dark themes. Accessibility and usability beat decoration. The [visual design specification](UX_DESIGN.md) lists required screen states, layouts, touch targets, TalkBack behaviour and future tablet/desktop support.

## Developers & contributors

~~~sh
git clone https://github.com/parmtech/Tong-Ledger.git
cd Tong-Ledger
flutter create --platforms=android --org au.parmtech --project-name tong_ledger .
flutter pub get
flutter test
flutter analyze
flutter run
~~~

> Current source is an **in-memory developer demo**; any changes disappear after restart, and it must not be used for real financial data. Android debug CI should be treated as unverified until the first green run. Please read [security](SECURITY_PRIVACY.md) and [implementation status](IMPLEMENTATION_STATUS.md).

### Cross-platform direction

Business and presentation code uses Flutter/Dart so we can support Android, iPhone/iPad, Windows, macOS and Linux in the longer term. **Only Android release builds are in scope today**; Windows EXE optional when a suitable build runner is available. No other installer has been produced.

---

**Tong Ledger • Developed by ParmTech • Open Source (Apache 2.0)**

This page is a GitHub Markdown documentation portal. It can be copied into GitHub Wiki Home if Wiki is enabled; this repository file is the version-controlled source of truth.
