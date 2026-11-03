# Android-First Roadmap

| Phase | Output | Done when |
| --- | --- | --- |
| 0 — Foundation | Verified public repo, open-source license, comprehensive blueprint, designs, 30 budget plans | Documentation reviewed and linked |
| 1 — Domain MVP | Flutter root, ledger math, immutable budget presets, sample dashboard and unit tests | CI analyze/test green; example calculations correct |
| 2 — Real local management | Create/edit/disable banks, multiple accounts, cards, private and bank loans, assets, income, transactions, actual balances | All flows work with encrypted SQLite and survive restart |
| 3 — Budget Pro | Editable template clones, schedules, savings goals, bills, charts, real safe-to-spend projections | Domain and UI integration tests pass |
| 4 — Premium polish | Luxury responsive design, accessibility, language-ready strings, complete lessons, backup/restore, import/export | Security/usability/performance audits pass |
| 5 — Android launch | Signed APK for testers and signed AAB for Play, policies/listing, staged rollout | Play approval and post-release monitoring |
| Later | Optional Windows EXE, then iPhone/macOS/Linux, household sync, CDR provider integration | Each platform separately tested and consent/legal review satisfied |

## Scope controls
No non-Android build is required before Android launch. A Windows EXE may be explored if a real Windows runner/tooling exists, but do not block Android. Maintain code portability throughout. Finish correct accounting and reliable encrypted storage **before** adding AI or fancy decorative motion. Never present prototype demo data as real records. Release date intentionally not promised.
