# Recovery & Android Device Test Matrix (P0)

**Status:** This is a required manual QA checklist, **not** evidence tests passed. Test with fictional balances only. The GitHub Actions debug APK must not be considered production-safe until this matrix and threat review are completed.

| Test | Scenario | Expected result | Evidence |
|---|---|---|---|
| D01 | Create two manual banks, a card, loan, and custom budget; restart Android app | All records reload with exact cents | Pending |
| D02 | Export encrypted `.tlbackup` via native Android file picker; close app | File contains only authenticated ciphertext and metadata; no plaintext account names | Pending |
| D03 | Save backup outside app storage, uninstall app/reinstall on a separate test phone and restore | All sample accounts/cards/loans/budgets return exactly; old device key not required | Pending |
| D04 | Supply wrong backup password | Authentication fails; existing device vault remains unchanged | Pending |
| D05 | Flip 1 bit in the saved backup ciphertext or MAC | Tampering rejected; existing vault unchanged | Pending |
| D06 | Simulate Android secure-key invalidation without deleting encrypted vault | Locked screen opens, no silent empty-vault reset; "Recover from encrypted backup" visible | Pending |
| D07 | After key loss, restore a valid backup using password | User confirms replacement; old ciphertext preserved; restored sample accessible after restart | Pending |
| D08 | Cancel before confirming replacement | Old encrypted file and key unchanged | Pending |
| D09 | Force-close during export/import or kill process at staged-key write | No fake success; startup either resumes authenticated recovery or retains old readable vault | Pending |
| D10 | Fill storage to near-capacity, attempt restore | No data loss; old active data preserved or app remains explicitly locked for recovery | Pending |
| D11 | Android system backup/transfer between test devices | Generated manifest disables automatic backup / transfer for private vault; no unkeyed ciphertext auto-restored | Pending |
| D12 | Restore on an Android phone with different OS/API level and biometric/lock changes | Portable backup restore works; loss of original key never silently resets records | Pending |
| D13 | Large backup file over 16 MiB / bad schema / orphan link / unbalanced transaction | Rejected before committing any file replacement | Pending |
| D14 | Run with TalkBack and 200% font size, close/reopen passphrase dialog | Controls accessible, no clipped destructive confirmation, no crashes | Pending |
| D15 | Encrypt backup twice with same book/password | Random salt/nonce produce distinct ciphertext; both decrypt | Pending |
| D16 | Inspect apk with Android manifest dump | `allowBackup=false` and restricted backup/data extraction rules are present in compiled artifact | Pending |

## Procedure for testers

1. Use only invented institutions, amounts and passwords; never use personal banking data. Use separate test devices or Android emulators that can be reset safely.
2. Capture the Android device/OS version, app commit, workflow run and a screenshot of the successful / failed UI. **Never** capture or upload backup passwords or plaintext records.
3. For forced failures, use controlled debug hooks/test injection or emulator snapshots; don't damage a personal phone.
4. Record exactly which record counts and balances were restored. Include comparison against the exported fixture.
5. Mark each row Pass/Fail/Blocked, with dated evidence. No row can be marked Pass merely because a unit test passed.
6. Retain the last good encrypted backup and keep the password separately. A preserved ciphertext file may be unreadable if the device key is gone.
7. Block all public releases if D03/D06/D07/D09/D10/D11 or D16 fail.

## Remaining engineering work

- Native Android platform sources should be pinned rather than generated only in CI; until then `scripts/prepare_android.py` must run immediately after `flutter create` and be verified in every Android build.
- Standalone user-facing "verify my backup" flow, independent OS-specific testing of Keystore invalidation and low-disk fault injection, encrypted database/journal migration, and external security review are still required.
- Documentation: [Recovery Protocol](LOCKED_VAULT_RECOVERY_PROTOCOL.md) and [Engineering Roadmap](ENGINEERING_ROADMAP_V2.md).

Do not publish a signed production AAB based on this test matrix alone. Completion needs documented evidence and responsible release review.
