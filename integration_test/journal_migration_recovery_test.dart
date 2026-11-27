import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/journal_key_manager.dart';
import 'package:tong_ledger/storage/journal_migration_recovery.dart';
import 'package:tong_ledger/storage/vault_key_access.dart';

class TestKeys implements VaultKeyAccess {
  final values = <String, String>{};
  int writes = 0;

  @override
  Future<String?> read(String slot) async => values[slot];

  @override
  Future<void> write(String slot, String value) async {
    writes++;
    values[slot] = value;
  }

  @override
  Future<void> delete(String slot) async {
    values.remove(slot);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restart reuses verified candidate and missing key blocks recovery',
      (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('native-recovery-test-');
    final keys = TestKeys();
    final source = FinanceBookCodec.encode(createDemoBook());
    try {
      final first = await JournalMigrationRecovery(JournalKeyManager(keys))
          .prepareOrResume(stagingRoot: root, sourceSnapshot: source);
      final resumed = await JournalMigrationRecovery(JournalKeyManager(keys))
          .prepareOrResume(stagingRoot: root, sourceSnapshot: source);
      expect(resumed.path, first.path);
      expect(keys.writes, 1);
      await keys.delete(JournalKeyManager.slot);
      await expectLater(
        JournalMigrationRecovery(JournalKeyManager(keys)).prepareOrResume(
          stagingRoot: root, sourceSnapshot: source,
        ),
        throwsA(isA<JournalKeyFailure>()),
      );
      expect(await first.exists(), isTrue);
      expect(keys.writes, 1);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
