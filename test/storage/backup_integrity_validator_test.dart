import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/storage/backup_integrity_validator.dart';
import 'package:tong_ledger/storage/passphrase_backup.dart';

void main() {
  test('valid fictional finance records pass backup integrity checks', () {
    expect(() => BackupIntegrityValidator.validate(createDemoBook()),
        returnsNormally);
  });

  test('unknown institution links are rejected before exporting a backup', () {
    final data = FinanceBook(
      accounts: [
        const CashAccount(id: 'account', name: 'Cash',
          institutionId: 'missing', openingCents: 12000),
      ],
    );
    expect(() => BackupIntegrityValidator.validate(data),
        throwsFormatException);
  });

  test('orphan-linked cards, loans and income are rejected', () {
    final invalid = [
      FinanceBook(cards: [
        const CreditCardAccount(id: 'card', name: 'Card',
          limitCents: 10000, openingOwedCents: 2000,
          institutionId: 'missing'),
      ]),
      FinanceBook(loans: [
        const LoanAccount(id: 'car', name: 'Car', lenderName: 'Private',
          openingOutstandingCents: 5000, institutionId: 'missing'),
      ]),
      FinanceBook(incomeSources: [
        const IncomeSource(id: 'salary', name: 'Work',
          cadence: 'weekly', expectedCents: 15000,
          destinationAccountId: 'missing'),
      ]),
    ];
    for (final book in invalid) {
      expect(() => BackupIntegrityValidator.validate(book),
          throwsFormatException);
    }
  });

  test('an unbalanced account movement is blocked before backup', () async {
    final book = FinanceBook(
      accounts: [
        const CashAccount(id: 'a', name: 'Savings', openingCents: 30000),
      ],
      entries: [
        LedgerEntry(
          id: 'bad-transfer', type: LedgerType.transfer,
          amountCents: 1000, sourceAccountId: 'a',
          destinationAccountId: 'a', at: DateTime.utc(2026, 11, 4),
        ),
      ],
    );
    expect(() => BackupIntegrityValidator.validate(book),
        throwsFormatException);
    await expectLater(
      PassphraseBackup().create(book, 'this-is-a-long-example-password'),
      throwsA(isA<Exception>()),
    );
  });
}
