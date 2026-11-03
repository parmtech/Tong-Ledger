import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Injectable key storage boundary so recovery can be tested without a device.
abstract class VaultKeyAccess {
  Future<String?> read(String slot);
  Future<void> write(String slot, String value);
  Future<void> delete(String slot);
}

class AndroidVaultKeyAccess implements VaultKeyAccess {
  AndroidVaultKeyAccess(FlutterSecureStorage storage) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String slot) => _storage.read(key: slot);

  @override
  Future<void> write(String slot, String value) =>
      _storage.write(key: slot, value: value);

  @override
  Future<void> delete(String slot) => _storage.delete(key: slot);
}
