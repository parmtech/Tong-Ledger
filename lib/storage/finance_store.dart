import '../domain/finance_models.dart';

/// Interface for persisted finance data. The UI never reads plaintext files.
abstract class FinanceStore {
  Future<FinanceBook> load();
  Future<void> save(FinanceBook book);
}
