import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/ledger_engine.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';

void main() {
  test('all entity types survive a versioned encode/decode round-trip', () {
    final original = createDemoBook();
    original.selectedBudgetTemplateId = 'plan_08';
    final encoded = FinanceBookCodec.encode(original);
    final restored = FinanceBookCodec.decode(encoded);
    expect(restored.institutions.single.name, 'Commonwealth Bank');
    expect(restored.accounts.length, 3);
    expect(restored.cards.single.limitCents, 800000);
    expect(restored.loans.single.lenderName, 'Private Car Finance');
    expect(restored.assets.single.valuationCents, 2200000);
    expect(restored.incomeSources.single.cadence, 'fortnightly');
    expect(restored.entries.single.category, 'Groceries');
    expect(restored.selectedBudgetTemplateId, 'plan_08');
    expect(calculateLedger(restored).cashCents,
        calculateLedger(original).cashCents);
  });

  test('unknown schema version is rejected rather than reset', () {
    final encoded = FinanceBookCodec.encode(createDemoBook());
    expect(
      () => FinanceBookCodec.decode(encoded.replaceFirst('"schema":1', '"schema":3')),
      throwsFormatException,
    );
  });

  test('invalid transaction link is rejected before any save', () {
    final encoded = FinanceBookCodec.encode(createDemoBook());
    expect(
      () => FinanceBookCodec.decode(
        encoded.replaceFirst('"sourceAccountId":"expenses"',
            '"sourceAccountId":"missing"'),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
