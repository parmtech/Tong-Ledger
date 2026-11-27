import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/storage/journal_migration_recovery.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('journal-evidence-test-');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<Directory> stage() => root.createTemp('sqlcipher-stage-');

  test('empty staging directory permits first creation', () async {
    expect(await JournalStageEvidence.inspect(root), isNull);
  });

  test('unfinished directory blocks new provisioning and is preserved', () async {
    final incomplete = await stage();
    await expectLater(JournalStageEvidence.inspect(root),
      throwsA(isA<JournalStageRecoveryFailure>()));
    expect(await incomplete.exists(), isTrue);
  });

  test('zero-length candidate blocks restart without deleting evidence', () async {
    final dir = await stage();
    final file = File('${dir.path}${Platform.pathSeparator}journal.db');
    await file.create();
    await expectLater(JournalStageEvidence.inspect(root),
      throwsA(isA<JournalStageRecoveryFailure>()));
    expect(await file.exists(), isTrue);
  });

  test('single candidate is found and rollback sidecars remain untouched', () async {
    final dir = await stage();
    final path = '${dir.path}${Platform.pathSeparator}journal.db';
    await File(path).writeAsString('fictional-candidate');
    final sidecar = await File('$path-journal').writeAsString('fictional-sidecar');
    expect((await JournalStageEvidence.inspect(root))?.path, path);
    expect(await sidecar.readAsString(), 'fictional-sidecar');
  });

  test('multiple candidates and unknown entries fail closed', () async {
    final first = await stage();
    final second = await stage();
    await expectLater(JournalStageEvidence.inspect(root),
      throwsA(isA<JournalStageRecoveryFailure>()));
    expect(await first.exists(), isTrue);
    expect(await second.exists(), isTrue);
  });

  test('unrecognized file blocks restart', () async {
    final file = await File('${root.path}${Platform.pathSeparator}unknown')
        .writeAsString('evidence');
    await expectLater(JournalStageEvidence.inspect(root),
      throwsA(isA<JournalStageRecoveryFailure>()));
    expect(await file.readAsString(), 'evidence');
  });
}
