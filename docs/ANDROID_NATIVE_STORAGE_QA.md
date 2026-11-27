# Android native storage QA

The original foundation CI passed at commit 095e560 (https://github.com/parmtech/Tong-Ledger/actions/runs/45950291826). It runs analysis, host unit/widget tests and compiles a debug APK; it does not execute Android integration tests.

The new separate workflow runs the integration_test suite on an Android API 34 x86_64 emulator. The emulator action is pinned to the inspected v2 commit a421e43855164a8197daf9d8d40fe71c6996bb0d. It has read-only repository permissions and does not use signing or real financial data. Two new tests exercise real platform secure-storage retrieval/loss and native SQLCipher transaction rollback after an injected SQLite abort. Emulator verification is pending until a successful workflow run is observed.

This is not a physical-device test, hardware-backed Keystore attestation, actual process-kill/power-loss test, disk-full test, or independent security audit. The existing vault remains authoritative. Do not activate production storage or release a build before the remaining migration, backup, app-lock and physical-device acceptance gates.
