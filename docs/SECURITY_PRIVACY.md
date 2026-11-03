# Security & Privacy Engineering Plan

## Current warning
Current MVP code is a **development foundation**, not a safe vault for real records. Encrypted persistence, release signing, external assessment and data portability are required before launch. Do not collect or publish personal bank information in issues or telemetry.

## Threat model
Assets: financial balances, notes, transactions, optional last four card digits, backups, keys, account labels. Adversaries: stolen/lost device, malware, malicious backup files, accidental Git commits, compromised third-party dependencies, insecure analytics, local logs, unauthorised household member, compromised device cloud sync. No online-banking passwords are collected.

## Controls
1. Local database encryption at rest with authenticated encryption and OS-protected key material; test Android key invalidation and device migration cases.
2. User-selected PIN/biometrics using system prompt and timeouts; protect against screenshots in private mode, handle app switcher previews.
3. A backup format that is encrypted, integrity-protected, versioned and user-passphrase-derived; no default unencrypted exports of raw finances without explicit warnings/confirmation.
4. Single-writer or transaction-safe ledger, migration rollback and hashed/checksummed backup with safe atomic restore.
5. Avoid recording account numbers, full card numbers, passwords, backup passphrases, actual balances or payee descriptions in crash logs.
6. Supply-chain pinning/version updates, dependency audit, SAST, secret scanning, review gates and SBOM before release.
7. CSV/JSON import size limits, schema checks, duplicate detection, and spreadsheet-formula escaping in exports.
8. Transparent data handling, real-world deletion/export options, no covert AI analysis or sharing; external connectors opt-in only.
9. If syncing later: end-to-end encryption, device enrolment, revocation, conflict handling, and identity/authentication review.
10. Privacy policy, Google Play Data Safety and applicable financial features declaration verified against implemented behaviour at release.

## Regulatory/product boundaries
This is a manual organiser, not a bank, financial adviser, lender, payment processor or Australian CDR data recipient in v1. Do not present it as licensed or connected to a bank. If future CDR connectivity is contemplated, undertake legal, security and provider review first. Avoid claims of guaranteed financial forecasts.

## Release security gate
Block production until encrypted database is implemented + tested, account/card/loan edit integrity validated, sensitive export/import guarded, security review and recovery tested, permissions minimal and privacy disclosures accurately match app data flows.
