# Tong Ledger — Implementation Status

**2026-11-03 · Development candidate only**  
**Current feature branch:** `feature/secure-local-vault` · Main branch may still contain the previous in-memory demo until this PR is merged.

### On main before this branch
- Comprehensive A-to-Z spec, privacy model, budget plans (30 across 6 groups), UX/tutorials, roadmap, permanent handoff.
- Flutter demo navigation, data models, money/ledger engine, initial tests and Android CI workflow.

### Added on secure-local-vault branch
- AES-256-GCM **encrypted snapshot file** with secret key in Android-protected secure storage, nonce per save, authenticated envelope.
- Versioned codec storing institutions, accounts, credit cards, loans, assets, income sources, entries and selected budget plan.
- Fail-closed loading: corrupted file / missing device key **does not overwrite existing data**.
- Atomic temp-and-rename save strategy on Android, and copy-before-save in the UI to preserve last successful visible state if a save fails.
- User data starts empty; demo data is explicit, fictional and isolated from the real vault.
- Forms now create real local data: banks, linked accounts/cards, bank or independent loans, income sources, assets, transfers and transactions.
- A budget template **selection** can persist; full user-editable categories and budget-book engine remain future work.
- Tests written for codec roundtrip, authentication and tampering, finance calculations, template integrity and fake UI storage.

### Still blocked / unverified
- Flutter/Dart SDK and Android SDK are unavailable in this conversation's execution container; **no local compile, test pass or APK verification**.
- Review GitHub Actions PR CI output and fix any lint/test/compilation failures before merge.
- No backup/recovery, biometric lock, audit log, user-owned template editor, full recurrence engine or approved Play production release.
- Security review, low-storage power-loss recovery tests and Android OS-keystore migration must pass first.
- No iOS, macOS, Linux or Windows build requested now, except Windows optional much later.

### Next milestone
1. Verify CI checks on the PR and fix them.
2. Test Android debug APK on a device using **fictional records only**.
3. Implement encrypted database migration, backup/restore + transactions, full CRUD/edit/archive and editable budgets.
4. Complete privacy policy, accessibility, signing and Play test tracks.

Do not call branch or app production-ready; no validated release binaries exist yet.
