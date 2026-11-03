import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/budget_plan.dart';
import 'package:tong_ledger/domain/budget_templates.dart';
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
  test('custom budget survives encrypted snapshot codec roundtrip', () {
    final book = createDemoBook();
    final plan = BudgetPlan.fromTemplate(
      id: 'my-budget', template: budgetTemplates[7],
      incomeCents: 275050, period: BudgetPeriod.fortnightly,
      startDate: DateTime.utc(2026, 11, 3),
    );
    book.budgets.add(plan);
    final restored = FinanceBookCodec.decode(FinanceBookCodec.encode(book));
    expect(restored.budgets.single.id, 'my-budget');
    expect(restored.budgets.single.incomeCents, 275050);
    expect(restored.budgets.single.period, BudgetPeriod.fortnightly);
    expect(restored.budgets.single.allocatedCents, 275050);
  });

  test('old v0.2 snapshot without budgets loads without any data loss', () {
    final book = createDemoBook();
    final json = jsonDecode(FinanceBookCodec.encode(book))
        as Map<String, dynamic>;
    json.remove('budgets');
    final restored = FinanceBookCodec.decode(jsonEncode(json));
    expect(restored.budgets, isEmpty);
    expect(restored.accounts.length, 3);
    expect(restored.cards.single.openingOwedCents, 230000);
  });

  test('invalid saved budget categories fail closed', () {
    final book = createDemoBook();
    book.budgets.add(BudgetPlan(
      id: 'bad', name: 'Bad', period: BudgetPeriod.monthly,
      startDate: DateTime.utc(2026, 11, 1), incomeCents: 100000,
      allocations: [
        const BudgetAllocation(category: 'Food', plannedCents: 12000),
        const BudgetAllocation(category: 'food', plannedCents: 13000),
      ],
    ));
    expect(
      () => FinanceBookCodec.decode(FinanceBookCodec.encode(book)),
      throwsFormatException,
    );
  });

}
