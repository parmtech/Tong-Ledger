import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/budget_plan.dart';
import 'package:tong_ledger/domain/budget_templates.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/passphrase_backup.dart';

void main() {
  final backup = PassphraseBackup();
  const password = 'sample-strong-27-character-passphrase';

  test('portable encrypted backup roundtrip retains budgets and accounts',
      () async {
    final book = createDemoBook();
    book.budgets.add(BudgetPlan.fromTemplate(
      id: 'home-budget',
      template: budgetTemplates[7],
      incomeCents: 260005,
      period: BudgetPeriod.fortnightly,
      startDate: DateTime.utc(2026, 11, 1),
    ));
    final envelope = await backup.create(book, password);
    expect(envelope, isNot(contains('Commonwealth Bank')));
    expect(envelope, isNot(contains('home-budget')));
    expect(envelope, isNot(contains(password)));
    final restored = await backup.open(envelope, password);
    expect(restored.accounts.length, 3);
    expect(restored.budgets.single.incomeCents, 260005);
    expect(FinanceBookCodec.encode(restored),
        FinanceBookCodec.encode(book));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('wrong password or changed ciphertext cannot decrypt', () async {
    final envelope = await backup.create(createDemoBook(), password);
    await expectLater(
      backup.open(envelope, 'incorrect-secret-passphrase-123'),
      throwsFormatException,
    );
    final data = jsonDecode(envelope) as Map<String, dynamic>;
    final bytes = base64Decode(data['ciphertext'] as String);
    bytes[0] ^= 1;
    data['ciphertext'] = base64Encode(bytes);
    await expectLater(
      backup.open(jsonEncode(data), password),
      throwsFormatException,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('weak passphrases and unsupported work factors are rejected', () async {
    await expectLater(
      backup.create(createDemoBook(), 'short'),
      throwsFormatException,
    );
    final envelope = await backup.create(createDemoBook(), password);
    final data = jsonDecode(envelope) as Map<String, dynamic>;
    data['iterations'] = 1;
    await expectLater(
      backup.open(jsonEncode(data), password),
      throwsFormatException,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('oversized or malformed backups are rejected before key derivation',
      () async {
    await expectLater(
      backup.open('not a json backup', password),
      throwsFormatException,
    );
    await expectLater(
      backup.open('x' * (PassphraseBackup.maxBackupBytes + 1), password),
      throwsFormatException,
    );
  });
}
