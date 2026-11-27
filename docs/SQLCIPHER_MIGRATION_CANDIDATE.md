# Verified SQLCipher migration candidate

The experimental candidate contains both the canonical revision-zero journal and a separate immutable canonical FinanceBook snapshot inside the encrypted database. This preserves all fields understood by the legacy codec, including budgets, assets, institutions and income sources, rather than only journal balances. Creation checks that the snapshot projects to the initial journal. Independent reopen compares both representations to the source.

The legacy ciphertext remains untouched. The stored snapshot is historical migration evidence, not current app state after journal edits. This does not implement normalized metadata tables, a production upgrade from earlier experimental databases, key management, activation, rollback or process-kill recovery. Earlier experimental stage files without the snapshot table must be recreated, not silently upgraded.

Run: flutter test integration_test/sqlcipher_migration_candidate_test.dart -d <device-id>. Native device verification is still required.
