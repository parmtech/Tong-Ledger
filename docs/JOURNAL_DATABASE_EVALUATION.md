# P0 encrypted journal database evaluation

This is a developer-only milestone. The existing encrypted FinanceBook remains the source of truth. The revision codec is plaintext in memory only and is not a storage mechanism.

Candidate: sqflite_sqlcipher 3.4.1 (https://pub.dev/packages/sqflite_sqlcipher/versions/3.4.1). Its documentation describes SQLCipher 4.x, Android/iOS/macOS and password-based database opening. The wrapper lists MIT licensing; review transitive native licenses, provenance, current security support, Android ABI/page-size compatibility, and release shrinking rules before adopting. Windows support is not claimed. Another candidate is sqlite3 with its documented native encryption build hooks (https://pub.dev/packages/sqlite3).

Acceptance gates before activation:
- Pin and review the selected dependency, verify native cipher availability and fail closed if unavailable.
- Generate a separate high-entropy database key; use platform secure storage; never log it or use a hardcoded secret.
- Commit transaction header, postings and revision together. Reject stale revision, duplicate IDs, unbalanced entries and unknown accounts.
- Verify wrong-key refusal, tampered files, reopened balances, interrupted commits, full disk, rollback, and concurrent writer behavior on real devices.
- Keep legacy ciphertext and portable backup independent; no automatic activation or destructive replacement.
- Verify Android signed release, then iOS build and keychain/recovery separately.

No database dependency has been activated by this change. No production readiness claim.
