# SQLCipher staging key boundary

The JournalKeyManager uses the existing VaultKeyAccess abstraction and a separate secure-storage slot. It generates 32 random bytes only if no saved key and no existing database/recovery evidence are reported. It verifies persistence before returning a key and refuses malformed stored keys. Six focused tests use fictional in-memory key storage.

This is not a production key lifecycle. The caller must serialize access across instances/processes and discover all database and unfinished recovery evidence before provisioning. No active application integration, key rotation, portable recovery, native Keystore/Keychain verification or atomic key/database activation is implemented. The existing vault key slot is untouched.
