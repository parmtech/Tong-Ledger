# SQLCipher staging restart recovery

A dedicated private staging root is inspected before acquiring a key. Empty roots can initialize; a single recognized nonempty candidate is independently reopened and verified against the source. Partial, unknown or multiple candidates fail closed without deletion or replacement. A missing key for a recognized candidate prevents key regeneration. Native SQLite sidecars are preserved for reopening.

Six filesystem unit tests and one native restart integration test are included. Run the native test with flutter test integration_test/journal_migration_recovery_test.dart -d <device-id>.

This is not crash-proof production activation. A caller still must enforce exclusive filesystem/key access across isolates and processes and ensure the source is authenticated and not concurrently edited. A process-kill, disk-full, and real device key invalidation matrix remains required. The old vault stays authoritative and is not touched.
