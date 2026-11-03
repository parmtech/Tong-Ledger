# Tong Ledger — UX, Navigation and Luxury Design System v2

**Goal:** "Looks premium in five seconds, understood in ten, first useful action in two minutes." The interface must be easier than a complex banking app but more powerful when the user deliberately asks for detail. **Target Android first**.

## 1. Design philosophy

- **Quiet luxury**, not gold on every surface: restrained champagne highlights, soft deep-navy surfaces, purposeful typography, tactful depth, no noisy carousels/particle effects.
- **Answer → Explain → Act:** headline number, small label/as-of date, optional details, one obvious next step.
- **No fake financial precision:** dates, data source and pending/estimated status always displayed where relevant.
- **Progressive disclosure:** basic flow with 3–5 fields; advanced fields collapse under "More details". Beginner users should never have to fill a full loan application form.
- **One action vocabulary:** “Add”, “Record expense”, “Move money”, “Pay card”, “Save budget”, “Restore backup”. Never reuse "Deposit" for a forecast.
- **Never hide critical things:** screen readers, editable money fields, account-relationship labels, save errors and export warnings must be visible, not just animation or colour.

## 2. Five primary destinations

| Tab | Top-level purpose | Most common CTA | Contents |
| --- | --- | --- | --- |
| **Home** | "Where do I stand today?" | Add transaction | Cash, upcoming bill, budget progress, liabilities/net worth, recent activity |
| **Money** | "Where is my money/debt?" | Add institution/account/card/loan/asset | Bank groups, Accounts/Cards/Loans/Assets/Income filters |
| **Budget** | "How will I use my money?" | Create my budget | My Budgets, Templates, Goals, Bills, Plans vs Actual |
| **Activity** | "What happened?" | Record expense / transfer | Searchable, filterable ledger, grouped dates, correction/reconciliation |
| **Insights** | "What changed over time?" | Change date range | Cash-flow, net worth history, categories, debt progress, forecasts |

**Profile / Settings / Help / Backup**: user icon or top-right menu on all screens, never a primary bottom tab. For small-screen accessibility, label all tab icons in text. For tablets, use a navigation rail and a second pane where relevant.

## 3. Home dashboard: information hierarchy

### Proposed phone layout (content wireframe)

~~~text
┌──────────────────────────────────────────┐
│ TL  Good evening             [?] [⚙]    │
│ Updated manually • 2 days ago            │
│                                          │
│ MONEY IN ACCOUNTS                         │
│ A$ 9,825.00                      [eye]   │
│ Savings + Everyday + Cash       [See]    │
│                                          │
│ NEXT UP                                  │
│ Card payment • 12 Nov • A$ 250    [View] │
│                                          │
│ MY BUDGET  •  THIS FORTNIGHT             │
│ Used A$ 620 of A$ 1,900   [bar] 33%      │
│ [Review categories]                      │
│                                          │
│ CREDIT & LOANS                           │
│ Card owed A$ 2,300  | Loans A$ 15,000   │
│ [Debt details]                           │
│                                          │
│ RECENT ACTIVITY                          │
│ Groceries  -A$75  • Expenses account    │
│ Salary     +A$... • Salary account      │
│ [See all activity]                       │
│                          [+ Add]         │
├──────────────────────────────────────────┤
│ Home  Money  Budget  Activity  Insights  │
└──────────────────────────────────────────┘
~~~

The amounts above are **fictional design examples only**. The app must have an equally considered *empty state* (see below), not seed fake figures in real accounts.

### Hierarchy rules
1. Show **cash assets** first and **outstanding debt** separately; never add credit limits into cash.
2. Next obligation is a small glanceable card with amount, due date and funding source, not a huge calendar.
3. Budget panel shows progress for selected plan; if none, one clear "Choose a budget plan" CTA.
4. Net worth is in Insights or a secondary expandable Home card, clearly marked estimate with valuation freshness.
5. "Available to spend" is hidden or shown as a labelled *projection* only after bills/account-scope logic is reliable.
6. Users can hide amounts with an eye icon; privacy state persists. Device notifications never reveal balances by default.
7. Show source "Manual entry / As of" for each group. If old, show "Review balance" rather than a false live indicator.
8. Home card order may be user-selectable **later**; polished default comes first.

## 4. Money: link institutions without trapping users

~~~text
Money
[Accounts] [Cards] [Loans] [Assets] [Income]
[All institutions ▼]           [+ Add]

Commonwealth Bank
  Everyday       A$ 800.00
  Salary         A$ 3,500.00
  Savings        A$ 5,500.00
  Linked credit card  A$ 2,300 owed
  [Open bank details]

OTHER LENDERS
  Private Car Finance
  Car loan      A$ 15,000 owed
~~~

- The institution detail screen should answer "what is linked to this bank?" but not mix liabilities and assets into one invented total.
- Cards, Loans, Assets and Income each have **global independent views**. The selected filter does not alter where records physically live.
- "Add Bank" offers quick suggestion search or custom name entry. Users may start with cash or a private loan without first creating a bank.
- Edit relationships in separate actions; changing the name of a bank does not change transactions.

## 5. Budget: one journey from 30 templates to a personal plan

### Template discovery (no wall of 30 items)
1. Header: "**Choose a ready-made budget**" + "**Start from scratch**".
2. Optional 3-question assistant, entirely local: **Your situation** (Student / Job / Family / Self-employed / Goal), **Pay cycle**, **Main goal**.
3. Three suggested presets with brief reason labels **"Good starting point for fortnightly pay"**, not financial-advice claims.
4. Six collection cards; tap a collection to expand its five presets; searchable full list via “See all”.
5. Template preview displays category percentages, example money amounts based on **user-entered planned take-home income**, and exclusions: "This plan might not cover your actual minimum loan repayments."
6. **Make it mine** copies the preset, navigates to editor; never edits source.
7. Editor: editable name, start date/period, planned income, stacked percentage + AUD amount view; categories reorderable and optional (but safe total validation).
8. Save with allocation summary; if overcommitted, show remaining negative amount and explicit confirmation.
9. Plan card: current period, budget used %, recent overages, top three categories, and a full breakdown drill-down.

### Category card (example)
~~~text
Groceries                          A$185 / A$300
█████████████░░░░░░  62%
Remaining A$115
[Transactions] [Edit limit]
~~~

**Important:** category IDs do not change when category labels are renamed; a transaction is counted once per budget scope. For zero allocations, show "No amount planned" not misleading 0%-full bar.

## 6. Activity: transactional trust

One unified timeline: date sections, amount sign, payee/label, source account/card, category chip and status badge.

Primary activity actions:
- "Expense" → choose bank account or card, category, positive AUD amount, date, note.
- "Income received" → choose landing account; optionally link income source.
- "Move money" → choose from/to bank accounts and amount; never counted as spending.
- "Pay card" → choose source bank account and card; never counted as second expense.
- "Pay loan" → choose loan and source bank account; interest/principal split explicit.
- "Refund / Correct" → reference original transaction; no destructive mutation of journal history.

**After-save review** says exactly what changed, e.g. “Expenses account -A$75; Groceries budget +A$75 spent”. No mystery spinning progress.

**Search & filters:** all / expenses / income / transfers / cards / loans; date range, institution, category and amount. Display sync/recorded status distinctly. Export data only from gated settings, not by long-press menu surprise.

## 7. Screen inventory and interactions

| Screen | User sees | Main action | Empty / error state |
| --- | --- | --- | --- |
| Welcome | Privacy promise and 3 options | Start manually | No mandatory login |
| Home | Cash, obligations, budget progress, recents | + Add | "Add your first account" with relevant action |
| Money list | Institution accordion and global filters | Add record | Per-type education and clear CTA |
| Bank detail | Linked accounts/cards/loans, separate totals | Add linked account | "No accounts here yet" |
| Account detail | Balance, as-of, statement, entries | Record, reconcile, rename/archive | Safe correction; never silently edit balance |
| Credit card detail | Owed, limit, statement due, payment progress | Pay card | No due-date fake value |
| Loan detail | Outstanding, lender, split repayment, schedule | Record payment | Missing interest split disclosed |
| Assets list/detail | Dated valuations and optional linked debt | Revalue | Stale valuation reminder |
| Budget library | My Plans and six preset collections | Make it mine | "Try a ready-made budget" |
| Budget editor | Live allocation and remaining amount | Save plan | Warn if totals exceed income |
| Activity | Search/filter transaction journal | Add/correct/reconcile | No transactions yet; add first |
| Insights | Trends, estimates, filters | Select period | No chart with invented values |
| Data & Backup | Export, import, restore, key warnings | Protected backup | Recoverable error guidance, no silent reset |
| Academy | Quick Start, eight lessons, glossary | Learn/restart | Offline lessons |
| Settings | Theme, language, privacy, notifications | Update options | No hidden destructive settings |

## 8. Interaction details and microcopy

**Good messages**
- "Saved on this device" (only after confirmed encrypted persistence)
- "This is a manual balance as of 3 Nov"
- "Your card has A$5,700 of available credit; this is not cash"
- "Scheduled payment, not recorded as paid"
- "Could not open your vault. Your encrypted file was not reset"
- "You are about to replace all records; create a backup first"
- "These totals are estimates based on the information you entered"

**Avoid**
- "No messages / no data" while loading
- "Current bank balance" when bank isn't connected
- "Available money" for credit limit
- "Payment sent" when the app only recorded a manual payment
- Unexplained cryptic abbreviations, unclickable teaching text and faux-functional UI.

## 9. Visual tokens

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| Background | \`#0C1117\` obsidian | \`#F6F4F0\` porcelain | Main canvas |
| Surface | \`#1B2633\` graphite | \`#FFFFFF\` | Cards and sheets |
| Accent | \`#C8AE7D\` champagne | Dark \`#1B2633\` text with champagne strokes | Key accents, focus and borders |
| Success | \`#6CD6AE\` | Deep emerald text (contrast verified separately) | Positive status, not the only indicator |
| Warning | \`#E9B976\` | Rich amber on light surfaces (contrast verified separately) | Overdue, underfunded |
| Negative | \`#E88B90\` | Dark red variant on light surfaces | Debt, alert |
| Primary text | Near-white | \`#1B2633\` | Readable financial information |
| Secondary text | Cool neutral grey, contrast tested | Dark slate, contrast tested | Dates/context |

Dark-text contrast examples calculated against design background: champagne on obsidian **8.85:1**, champagne on graphite **7.15:1**, graphite on porcelain **13.94:1**. These are preliminary palette-pair ratios; check each final component combination including disabled overlays, selection, small labels and chart colours.

Spacing: 4dp base, common 8/12/16/24/32dp. Rounded corners: 12dp inputs, 16–20dp cards; no giant radius that sacrifices content. Body 14–16sp, summary numbers 28–36sp depending on screen and Dynamic Type, use tabular numeric font features and locale currency grouping. Target touch minimum 48×48dp. Avoid embedded video and constant animation on finance pages.

## 10. Motion, responsiveness and accessibility

- Navigation and card state transitions 160–280ms with reduced-motion override.
- No auto-scrolling dashboards; no animation that obscures amount changes.
- 320–390dp small phones: single column, full-width labels, no horizontal clipped totals; long currency numbers wrap or shrink safely within a tested range.
- 391–599dp: standard two-up compact metrics only if accessible at large text.
- >=600dp tablets/foldables: navigation rail + content region; optional two-panel Money and Activity detail.
- Desktop later: keyboard navigation, resizable panes, larger density and shortcuts, with domain shared.
- TalkBack: semantic label includes **value, unit, role, source/as-of and action**. Don't rely on red/green alone. All charts have text summaries.
- Support at least 200% system text scaling without buttons overlapping. Verify different locales and right-to-left readiness; full RTL support targeted with translations.
- Light/dark/system contrast tests; no decorative logo cutouts inside text; screen capture privacy option for sensitive pages.

## 11. User research / acceptance tasks

Conduct at least five novice usability sessions before broad beta. Give each participant **fictional data only**.

| Task | Target measure |
| --- | --- |
| Add a bank and two distinct accounts | <3 minutes without external help |
| Add private car loan without bank | User finds a route on first attempt |
| Record a groceries card purchase | User sees debt increase and bank cash unchanged |
| Pay card from salary account | User sees card debt/cash fall, no second expense |
| Pick and customise a budget template | <90 seconds from picker to saving |
| Locate a card due date | User finds in <15 seconds |
| Find and correct transaction category | Under 30 seconds, no balance change |
| Export and restore fictional backup | No ambiguity about replace vs merge |
| Increase text to 200% | No clipped actions or unreadable figures |
| Explain what "A$ cash" means | User correctly states manual/as-of, not live bank data |

Collect task success rate, wrong-tap count, assistance needed, and participant confusion; use these to prioritise UI changes.

## 12. Design definition of done

Each screen must have: default/empty/loading/success/error states, action and undo/confirmation behaviour, keyboard/TalkBack path, small phone + tablet layout, dark/light contrast checks, input validation, privacy check and widget screenshot/test. This document is the **UI implementation contract**, not a claim those screens exist today.
