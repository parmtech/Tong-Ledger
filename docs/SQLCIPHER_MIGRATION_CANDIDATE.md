# Verified SQLCipher journal migration candidate

The candidate service projects a validated legacy FinanceBook in memory, creates a unique SQLCipher staging database, closes it and independently reopens it with the supplied key. It compares the entire canonical revision-zero journal against the original source projection, not just totals. A mismatched projection is rejected. The original vault is never opened or replaced by this service.

This is journal-only migration. Institutions, budget plans, asset valuations, other legacy metadata and the source ciphertext must remain available; matching journal postings does not establish complete FinanceBook equivalence. No production activation, key management, filesystem crash recovery or rollback is implemented here.

Run on Android or iOS test devices: flutter test integration_test/sqlcipher_migration_candidate_test.dart -d <device-id>. Tests are fictional and do not require real financial data. Native SQLCipher execution must be verified separately from static analysis and ordinary unit tests.
