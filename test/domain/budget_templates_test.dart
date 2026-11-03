import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/budget_templates.dart';

void main() {
  test('30 distinct budget plans in 6 collections, each exactly 100%', () {
    expect(budgetTemplates, hasLength(30));
    expect(budgetCollections, hasLength(6));
    expect(budgetTemplates.map((e) => e.id).toSet(), hasLength(30));
    for (final plan in budgetTemplates) {
      expect(plan.totalPercent, 100, reason: plan.name);
      expect(plan.allocations.values.every((value) => value >= 0), isTrue);
    }
  });
  test('allocation preserves every cent for arbitrary income', () {
    for (final plan in budgetTemplates) {
      for (final cents in [0, 1, 99999, 250001]) {
        final allocations = plan.amountsFor(cents);
        expect(allocations.values.fold(0, (a, b) => a + b), cents,
          reason: plan.name);
      }
    }
  });
}
