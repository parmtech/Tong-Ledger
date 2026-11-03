import '../domain/finance_models.dart';

/// Interface for persisted finance data. The UI never reads plaintext files.
abstract class FinanceStore {
  Future<FinanceBook> load();
  Future<void> save(FinanceBook book);
}


/// Explicit, user-confirmed import of an authenticated and validated backup.
/// Implementation must preserve previous ciphertext and fail closed.
abstract class RecoverableFinanceStore implements FinanceStore {
  Future<void> restoreVerifiedBackup(FinanceBook restored);
}
