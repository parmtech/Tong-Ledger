# Native SQLCipher staging checkpoint — schema 2

Experimental staging adapter, not the production database. Schema 2 normalizes journal accounts, transaction batches and postings into separate indexed, foreign-key-checked tables. Each append inserts only its new batch/postings and updates the revision in one SQLite transaction. Readback verifies row ordinals, the initial-plus-appended batch count and canonical balanced journal invariants. SQL triggers guard against accidental UPDATE or DELETE of historical rows. These constraints are not cryptographic immutability against a malicious database key holder.

The legacy canonical snapshot is retained as ordered UTF-8 BLOB chunks (128 KiB each), avoiding one oversized cursor row. It is historical migration evidence, not current state after edits. The staging limits are 100,000 accounts/batches, 400,000 postings, 64 MiB canonical journal and 32 MiB UTF-8 snapshot. These are safeguards, not measured device performance targets. The adapter still reads and validates the whole journal for each append. Account registration after staging, current metadata editing, indexed query APIs, active app integration and portable recovery of new transactions remain unimplemented.

Earlier experimental schema-1 databases are rejected without replacement. Never delete or recreate unknown or interrupted migration evidence automatically. The existing legacy vault remains authoritative.

Dependency: sqflite_sqlcipher 3.4.1. Native integration tests run via the separate Android emulator workflow; physical devices, interrupted process/storage failure, key invalidation, dependency/ABI/licence audit and app-lock/privacy remain required. No production activation or release.
