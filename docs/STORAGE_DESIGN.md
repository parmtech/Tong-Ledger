# Encrypted Local Storage — v0.2 Candidate

## Status
**Implemented on feature branch; NOT yet a production release or validated build.** No full backup / disaster recovery. Data from this experimental build should not be treated as safely recoverable. A real Android device test, migration exercise, accessibility pass and threat review must occur before publication.

## Why this architecture
Tong Ledger is manual-first, offline-first. Accounts, cards, loans, assets, income sources, transactions and selected template ID now have a versioned JSON **in-memory** representation. The JSON is AES-256-GCM encrypted before storage. The encryption key is stored separately in Android OS-protected secure storage (flutter_secure_storage). A new key is 32 bytes from a cryptographically secure RNG.

The vault file is placed in application support storage. Saving a finance book first validates ledger invariants, then creates a fresh nonce, encrypts and authenticates the complete snapshot, writes a same-directory temporary file with flush, and renames it to the active vault. It never deliberately deletes existing data before a replacement. If decryption, key recovery or schema validation fails, the app shows a **blocked error state**, never an automatic reset.

## Files
- `lib/storage/finance_store.dart`: UI-facing abstraction.
- `lib/storage/finance_book_codec.dart`: strict schema-v1 serializer/deserializer for all core records.
- `lib/storage/encrypted_document.dart`: AES-256-GCM encoder/decoder.
- `lib/storage/secure_finance_store.dart`: Android keychain/key retrieval and encrypted atomic snapshot file.
- `test/storage/*`: codec and tamper-detection tests.
- `lib/app/tong_ledger_app.dart`: encrypted loading, serialised saves and isolated fictional demo.

## What is currently saved
Institutions, multiple deposit accounts, credit cards, loans (including custom lenders), assets, income sources, transaction history and selected template ID. The UI allows manually adding these and recording income/expense, bank transfers, credit-card purchase/repayment, and loan repayment. Exiting a form before successful save leaves visible records unchanged. Demo mode uses no storage.

## Deliberate limits before public release
1. **No backup/export or restore yet.** Losing device or secure key can mean losing data. Do not market this as a fully ready finance vault.
2. **Single snapshot**: not yet encrypted SQLite/Drift. Large histories require migration to an indexed encrypted store, journaling and performance validation.
3. Android KeyStore backup/restore behaviour, Android auto-backup settings, key rotation, rooted-device threats, failure injection and power-loss recovery remain untested.
4. Encryption does NOT protect data displayed on a fully compromised/unlocked phone. PIN/biometric gate and screenshot protection are still pending.
5. Old prototype stored no user data; no automatic import needed. Future versions must add migrations and a documented emergency recovery procedure.
6. UI form validation and audit/archival are incomplete. Bank connection, web services and cloud sync are excluded.
7. Encrypted snapshot protocol must be independently reviewed; all builds and crypto tests need verified runner results.

## Required tests
AES-GCM round-trip and wrong-key/tamper rejection; schema version handling; round trip all entity types; ledger reference and cents integrity; fake-store widget startup; demo isolation. Further add real device tests: app restart preserves records; device backup/restore key mismatch safely blocks; interrupted writes keep old snapshot; 10,000+ records performance; Android lifecycle and OS version coverage.

## Follow-up
Integrate encrypted SQLite/Drift with transactional journal and migration from schema-v1 snapshot, durable backup/export and recovery, account editing/removal, full accessibility. Only then consider signed production AAB.
