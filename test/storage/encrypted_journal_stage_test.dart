import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/domain/ledger_engine.dart';
import 'package:tong_ledger/storage/encrypted_document.dart';
import 'package:tong_ledger/storage/encrypted_journal_stage.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';

void main() {
  late Directory root;
  late EncryptedJournalStage stage;
  late String source;
  final key = List<int>.filled(32, 17);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('journal-stage-test-');
    stage = EncryptedJournalStage();
    source = FinanceBookCodec.encode(createDemoBook());
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('ciphertext-only stage preserves balances and existing files', () async {
    final original = File('${root.path}${Platform.pathSeparator}original.enc');
    await original.writeAsString('original-test-ciphertext');
    final first = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    final second = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    final cipherText = await first.readAsString();
    expect(cipherText, isNot(contains('Commonwealth Bank')));
    expect(first.path, isNot(second.path));
    expect(await original.readAsString(), 'original-test-ciphertext');
    final book = FinanceBookCodec.decode(source);
    final actual = (await stage.verify(
      file: first, sourceSnapshot: source, key: key,
    )).project(book);
    final old = calculateLedger(book);
    expect(actual.cashAccounts, old.accounts);
    expect(actual.cardsOwed, old.cardsOwed);
    expect(actual.loansOwed, old.loansOutstanding);
    expect(actual.incomeCents, old.incomeCents);
    expect(actual.expenseCents, old.expenseCents);
  });

  test('wrong key and altered ciphertext are rejected', () async {
    final file = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    await expectLater(stage.verify(
      file: file, sourceSnapshot: source, key: List<int>.filled(32, 18),
    ), throwsA(isA<Exception>()));
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final bytes = base64Decode(data['ciphertext'] as String);
    bytes[0] ^= 1;
    data['ciphertext'] = base64Encode(bytes);
    await file.writeAsString(jsonEncode(data));
    await expectLater(stage.verify(
      file: file, sourceSnapshot: source, key: key,
    ), throwsA(isA<Exception>()));
  });

  test('authenticated but altered postings fail independent verification',
      () async {
    final file = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    final cipher = EncryptedDocument();
    final data = jsonDecode(
      await cipher.decrypt(await file.readAsString(), key),
    ) as Map<String, dynamic>;
    final batches = data['batches'] as List<dynamic>;
    final batch = batches.first as Map<String, dynamic>;
    final postings = batch['postings'] as List<dynamic>;
    final posting = postings.first as Map<String, dynamic>;
    posting['amountCents'] = (posting['amountCents'] as int) + 1;
    await file.writeAsString(await cipher.encrypt(jsonEncode(data), key));
    await expectLater(stage.verify(
      file: file, sourceSnapshot: source, key: key,
    ), throwsFormatException);
  });

  test('stage for different source cannot be accepted', () async {
    final file = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    await expectLater(stage.verify(
      file: file, sourceSnapshot: FinanceBookCodec.encode(FinanceBook()),
      key: key,
    ), throwsFormatException);
  });

  test('verified candidate is published without pending ciphertext', () async {
    final file = await stage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    );
    expect(file.uri.pathSegments.last, 'candidate.enc');
    final children = await file.parent.list().toList();
    expect(children.map((entry) => entry.path), [file.path]);
    await stage.verify(file: file, sourceSnapshot: source, key: key);
  });

  test('failed readback never publishes a candidate', () async {
    final failingStage = EncryptedJournalStage(cipher: _RejectReadback());
    await expectLater(failingStage.create(
      stagingRoot: root, sourceSnapshot: source, key: key,
    ), throwsFormatException);
    expect(await root.list().toList(), isEmpty);
  });

  test('invalid source cannot create a stage', () async {
    await expectLater(stage.create(
      stagingRoot: root, sourceSnapshot: '{"schema":999}', key: key,
    ), throwsFormatException);
    expect(await root.list().toList(), isEmpty);
  });
}

class _RejectReadback extends EncryptedDocument {
  @override
  Future<String> decrypt(String envelope, List<int> key) async {
    throw const FormatException('Simulated readback failure.');
  }
}
