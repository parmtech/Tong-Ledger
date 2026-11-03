# v0.4 — Locked-Vault Backup Recovery Protocol

**Status:** Experimental Android-first branch. Do not use real financial data or claim device-to-device recovery is complete before physical Android Keystore and power-failure testing. This work addresses the access-path defect tracked in [Issue #5](https://github.com/parmtech/Tong-Ledger/issues/5).

## What failed before

The earlier `BackupRestorePage` was only reachable after `SecureFinanceStore.load()` succeeded, and called `save()`. If a ciphertext vault existed and its Android device key was missing, `save()` refused to replace it. A valid password-encrypted backup therefore could not be used to recover from the blocked screen.

## Recovery workflow

1. The locked-vault page offers **Recover from encrypted backup**, with no requirement to unlock the broken local key.
2. User picks an encrypted `.tlbackup` file and enters its separate 12+-character backup passphrase. PBKDF2-HMAC-SHA256 derives the AES-256-GCM key. The ciphertext's authenticated tag and the complete finance schema must validate **before confirmation**.
3. Show exact account/card/loan/transaction counts and an explicit irreversible **Replace all records** confirmation.
4. Validate the restored `FinanceBook` again and create a fresh, random 256-bit device-vault key.
5. Write replacement ciphertext to a separate same-directory candidate file and decrypt it to verify it before touching active data.
6. If an active vault exists, copy its **original ciphertext** to a uniquely named `.preserved-*.enc` file. Never delete it as part of recovery. **Its original Android key may be unavailable**, so it is not necessarily recoverable.
7. Write the fresh key to a secondary Android-protected key slot and put down a nonsecret recovery-in-progress marker, then atomically activate the candidate on Android/Linux and promote the primary key.
8. A restart between file activation and primary-key promotion can authenticate using the secondary key and finish promotion. A restart with marker but no active file **does not create an empty vault**.
9. Wrong passphrase, invalid scheme, tampered backup, failed key write and interrupted operation cannot intentionally delete original ciphertext.

## Code

- `lib/storage/vault_key_access.dart`: OS key access adapter and injectable test boundary.
- `lib/storage/secure_finance_store.dart`: fail-closed staged recovery, separate protected recovery key, ciphertext preservation, interrupted promotion handling.
- `lib/storage/passphrase_backup.dart`: portable passphrase-encrypted finance snapshot.
- `lib/storage/backup_file_service.dart`: Android file-picking, ciphertext-only export/import.
- `lib/features/backup/backup_restore_page.dart`: locked-vault recovery UI and confirmation.
- `lib/app/tong_ledger_app.dart`: visible locked-vault recovery button.
- `test/storage/secure_finance_store_recovery_test.dart`: interrupted recovery, key invalidation simulation, preservation and no-empty-reset regression tests.
- Existing `test/storage/passphrase_backup_test.dart` tests authenticated backup roundtrips and tampering.

## Risks and next release gates

- This is still **single encrypted JSON snapshot storage**, not a transactional database/journal. Power-loss after hardware flush, Android path rename behaviour and KDF runtime on real devices are **not established by Flutter unit tests**.
- KeyStore plugin behaviour after actual device credential reset is not reproducible with a fake key adapter. Android-specific real-device testing is mandatory.
- Saved preserved ciphertext may consume storage; do not delete it automatically. Future UX must allow safe cleanup after a successful user-verified backup.
- On Android Auto Backup, local encrypted ciphertext must not be restored without keys; pin native Android manifests and backup exclusion rules after platform files are committed.
- User import is replacement-only; no merge/duplicate handling. Encrypted backup must be preserved separately, preferably outside the device.
- Password recovery is impossible without the chosen passphrase. The app does not upload, escrow or know it.
- Review backup file-size bound, plugin capabilities, accessibility, failed-write fault injections and production signing. Tests and a green debug APK **are not a production security review**.
