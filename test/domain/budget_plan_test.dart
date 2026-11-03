import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/budget_plan.dart';
import 'package:tong_ledger/domain/budget_templates.dart';
import 'package:tong_ledger/domain/finance_models.dart';

void main() {
  DateTime day(int month, int date) => DateTime.utc(2026, month, date);

  test('cloning a template creates an independent personal budget', () {
    final template = budgetTemplates.first;
    final plan = BudgetPlan.fromTemplate(
      id: 'personal-one', template: template,
      incomeCents: 250001, period: BudgetPeriod.fortnightly,
      startDate: day(11, 1),
    );
    expect(plan.allocations.fold<int>(
      0, (total, a) => total + a.plannedCents), 250001);
    expect(plan.templateId, template.id);
    final modified = BudgetPlan(
      id: plan.id, name: 'My own plan', period: plan.period,
      startDate: plan.startDate, incomeCents: plan.incomeCents,
      allocations: [
        const BudgetAllocation(category: 'Bills', plannedCents: 100000),
        const BudgetAllocation(category: 'Fun', plannedCents: 50001),
      ],
    );
    modified.validate();
    expect(modified.unallocatedCents, 100000);
    expect(template.allocations.keys, isNot(contains('Fun')));
    expect(plan.allocations.first.category, isNot('Bills'));
  });

  test('weekly and fortnightly budgets repeat on anchored dates', () {
    final base = BudgetPlan(
      id: 'a', name: 'Fortnight', period: BudgetPeriod.fortnightly,
      startDate: day(11, 2), incomeCents: 50000,
      allocations: [const BudgetAllocation(category: 'Food', plannedCents: 50000)],
    );
    expect(base.cycleStart(day(11, 15)), day(11, 2));
    expect(base.cycleStart(day(11, 16)), day(11, 16));
    expect(base.nextCycleStart(day(11, 16)), day(11, 30));
  });

  test('monthly cycle clamps Jan 31 to February end without drift', () {
    final plan = BudgetPlan(
      id: 'b', name: 'Monthly', period: BudgetPeriod.monthly,
      startDate: DateTime.utc(2026, 1, 31), incomeCents: 10000,
      allocations: [const BudgetAllocation(category: 'Bills', plannedCents: 10000)],
    );
    expect(plan.cycleStart(DateTime.utc(2026, 2, 28)), DateTime.utc(2026, 2, 28));
    expect(plan.nextCycleStart(DateTime.utc(2026, 2, 28)),
      DateTime.utc(2026, 3, 31));
  });

  test('actual spending ignores bank transfers, card payoff, and principal', () {
    final plan = BudgetPlan(
      id: 'a', name: 'Monthly', period: BudgetPeriod.monthly,
      startDate: day(11, 1), incomeCents: 200000,
      allocations: [
        const BudgetAllocation(category: 'Food', plannedCents: 50000),
        const BudgetAllocation(category: 'Interest', plannedCents: 5000),
      ],
    );
    LedgerEntry entry(
      String id, LedgerType type, String category, int cents,
      {int interestCents = 0, DateTime? at}
    ) => LedgerEntry(
      id: id, type: type, amountCents: cents,
      interestCents: interestCents, category: category,
      at: at ?? day(11, 3),
    );
    final actual = plan.actualSpending([
      entry('1', LedgerType.cashExpense, 'Food', 10000),
      entry('2', LedgerType.cardPurchase, 'Food', 3000),
      entry('3', LedgerType.cardPayment, 'Food', 3000),
      entry('4', LedgerType.transfer, 'Food', 3000),
      entry('5', LedgerType.loanPayment, 'Interest', 7000, interestCents: 500),
      entry('6', LedgerType.cardRefund, 'Food', 1000),
      entry('7', LedgerType.income, 'Food', 50000),
      entry('8', LedgerType.cashExpense, 'Food', 15000,
        at: day(12, 1)),
    ], day(11, 10));
    expect(actual['Food'], 12000);
    expect(actual['Interest'], 500);
  });

  test('duplicate category names, negative amounts and empty lists are rejected', () {
    BudgetPlan plan(List<BudgetAllocation> allocations) => BudgetPlan(
      id: 'a', name: 'My Plan', period: BudgetPeriod.weekly,
      startDate: day(11, 1), incomeCents: 120000,
      allocations: allocations,
    );
    expect(() => plan([]).validate(), throwsFormatException);
    expect(() => plan([
      const BudgetAllocation(category: 'Food', plannedCents: 100),
      const BudgetAllocation(category: 'food', plannedCents: 200),
    ]).validate(), throwsFormatException);
    expect(() => plan([
      const BudgetAllocation(category: 'Bills', plannedCents: -1),
    ]).validate(), throwsFormatException);
  });
}
