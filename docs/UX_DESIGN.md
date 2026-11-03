# Luxury Design & UX Specification

## Brand direction
Tong Ledger is premium and calm, not an imitation bank login screen. Obsidian #0C1117, graphite #1B2633, restrained champagne #C8AE7D, porcelain #F6F4F0, positive emerald #2D9478, careful red for debt/alerts. Gold is a highlight, not a text colour for every paragraph. High-contrast accessible light and dark palettes. Avoid excessive gradients, texture, shadows and motion that make money figures hard to read.

## Navigation and components
Home dashboard: net worth estimate (dated), cash available, cards owed, loans, upcoming bills, goals, budgets and recent activities. Money area: institution cards grouped, Accounts/Cards/Loans independent tabs, ability to open bank to show its 3 accounts + card + linked loan. Add flows are bottom sheets on mobile with strong validation, not confusing huge forms. Budget wizard: Select Template → Preview percentages → Enter Income and Cadence → Edit categories → Save Copy; never create a loan when selecting budget plan. Guided tutorials and live help are searchable.

## Screen inventory
Splash / welcome / permissions / lock / language / currency / profile selector / home / bank list / bank detail / account detail / card detail / loan list and detail / lender management / asset list and detail / income sources / transaction list and entry / transfer / budget library / budget editor / goals / bill calendar / analytics / what-if / settings / backup / tutorials / about. All states: empty, loading, validation, offline, permission rejected, error, success, saving, conflict and archived.

## Microinteractions
160–280ms basic animations with reduced-motion option. Haptic only if explicitly valuable and OS settings allow. Large numbers align with tabular numerals and negative amounts have visible sign and descriptive icon. All touch targets at least 48dp, responsive large text, clear text labels beside icons, right-to-left readiness. No hidden fees or silent auto-payment. Progress indicators must be distinguishable from balances.

## Responsive strategy
Android phones: 5 navigation destinations, full-width financial cards and sticky add action. Tablets: rail and split views. Windows later: resizable navigation, multi-pane widths and keyboard shortcuts. Keep business logic and content semantics identical across platforms while adapting navigation. Do not build non-Android installers yet.

## Brand art
A previous concept contains a gold TL ledger mark and editorial dashboard artwork. Treat them as **design references**, not final product screenshots. Repo includes a simple editable SVG placeholder in assets/brand/mark.svg. Source images must have confirmed rights and accessible text before publish. No font binary files committed.
