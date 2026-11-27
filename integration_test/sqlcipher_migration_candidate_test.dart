import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/sqlcipher_migration_candidate.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final key = List<int>.filled(32, 41); // Fictional test key only.

  testWidgets('legacy journal migrates, reopens and preserves source', (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('migration-candidate-test-');
    try {
      final original = File('${root.path}${Platform.pathSeparator}legacy.enc');
      await original.writeAsString('fictional-original-ciphertext');
      final source = FinanceBookCodec.encode(createDemoBook());
      final candidate = await SqlCipherMigrationCandidate.create(
        stagingRoot: root, sourceSnapshot: source, key: key,
      );
      await SqlCipherMigrationCandidate.verify(
        file: candidate, sourceSnapshot: source, key: key,
      );
      await expectLater(SqlCipherMigrationCandidate.verify(
        file: candidate, sourceSnapshot: FinanceBookCodec.encode(FinanceBook()),
        key: key,
      ), throwsFormatException);
      expect(await original.readAsString(), 'fictional-original-ciphertext');
      expect(await candidate.exists(), isTrue);
    } finally {
      await root.delete(recursive: true);
    }
  });

  testWidgets('invalid source creates no staging database', (tester) async {
    final root = await (await getApplicationSupportDirectory())
        .createTemp('migration-rejection-test-');
    try {
      await expectLater(SqlCipherMigrationCandidate.create(
        stagingRoot: root, sourceSnapshot: '{"schema":999}', key: key,
      ), throwsFormatException);
      expect(await root.list().toList(), isEmpty);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
