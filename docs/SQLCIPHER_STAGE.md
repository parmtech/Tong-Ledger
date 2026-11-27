# Native SQLCipher staging checkpoint

Experimental adapter, not the production database. It stores a canonical journal snapshot as one row per revision, updating the row within a SQLite transaction. This is an interim persistence proof, not normalized append-only posting tables. Legacy vault and UI are unchanged.

Dependency pinned to sqflite_sqlcipher 3.4.1; minimum Flutter 3.35 and Dart 3.9. Native device test: flutter test integration_test/sqlcipher_journal_stage_test.dart -d <device-id> on a generated platform project. For Android run scripts/prepare_android.py first. The test uses fictional data and a test-only key. Never use its key for real data.

Release remains blocked pending native tests, dependency and licensing audit, release shrinker configuration (including SQLCipher keep rules per package documentation), native ABI/page-size verification, production key lifecycle, normalized journal schema, independent recovery and real process-kill/disk-full tests. A passing debug build alone does not establish database security or recovery. No activation of this adapter in the application.
