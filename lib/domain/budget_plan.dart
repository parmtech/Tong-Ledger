import 'budget_templates.dart';
import 'finance_models.dart';

enum BudgetPeriod { weekly, fortnightly, monthly, yearly }

class BudgetAllocation {
  const BudgetAllocation({required this.category, required this.plannedCents});

  final String category;
  final int plannedCents;
}

/// An independent editable copy of a template, never a financial balance.
class BudgetPlan {
  BudgetPlan({
    required this.id,
    required this.name,
    required this.period,
    required this.startDate,
    required this.incomeCents,
    required this.allocations,
    this.templateId,
  });

  final String id;
  final String name;
  final BudgetPeriod period;
  final DateTime startDate;
  final int incomeCents;
  final String? templateId;
  final List<BudgetAllocation> allocations;

  int get allocatedCents =>
      allocations.fold<int>(0, (total, item) => total + item.plannedCents);

  int get unallocatedCents => incomeCents - allocatedCents;
  bool get isOverallocated => unallocatedCents < 0;

  void validate() {
    if (id.trim().isEmpty || name.trim().isEmpty || name.length > 100) {
      throw const FormatException('A budget must have an ID and short name.');
    }
    if (incomeCents < 0 || incomeCents > 100000000000000) {
      throw const FormatException('Invalid budget income amount.');
    }
    if (allocations.isEmpty || allocations.length > 100) {
      throw const FormatException('Add between 1 and 100 categories.');
    }
    final seen = <String>{};
    for (final item in allocations) {
      final category = item.category.trim();
      if (category.isEmpty || category.length > 80 ||
          !seen.add(category.toLowerCase()) || item.plannedCents < 0 ||
          item.plannedCents > 100000000000000) {
        throw const FormatException(
          'Category names must be unique and amounts cannot be negative.',
        );
      }
    }
    // Overallocations are permitted with a prominent warning in the editor.
  }

  factory BudgetPlan.fromTemplate({
    required String id,
    required BudgetTemplate template,
    required int incomeCents,
    required BudgetPeriod period,
    required DateTime startDate,
  }) {
    final values = template.amountsFor(incomeCents);
    final result = BudgetPlan(
      id: id,
      name: template.name,
      period: period,
      startDate: startDate,
      incomeCents: incomeCents,
      templateId: template.id,
      allocations: [
        for (final entry in values.entries)
          BudgetAllocation(category: entry.key, plannedCents: entry.value),
      ],
    );
    result.validate();
    return result;
  }

  /// Start date anchors recurring pay-cycle budgets.
  /// This calculation uses calendar dates in the provided UTC date space;
  /// callers convert a user's local calendar day to a UTC date-only value.
  DateTime cycleStart(DateTime asOf) {
    final anchor = DateTime.utc(
      startDate.year, startDate.month, startDate.day,
    );
    final day = DateTime.utc(asOf.year, asOf.month, asOf.day);
    if (day.isBefore(anchor)) return anchor;
    if (period == BudgetPeriod.weekly || period == BudgetPeriod.fortnightly) {
      final days = period == BudgetPeriod.weekly ? 7 : 14;
      final cycles = day.difference(anchor).inDays ~/ days;
      return anchor.add(Duration(days: cycles * days));
    }
    if (period == BudgetPeriod.monthly) {
      var months = (day.year - anchor.year) * 12 +
          day.month - anchor.month;
      var candidate = _monthAt(anchor, months);
      if (candidate.isAfter(day)) {
        months--;
        candidate = _monthAt(anchor, months);
      }
      return candidate;
    }
    var years = day.year - anchor.year;
    var candidate = _monthAt(anchor, years * 12);
    if (candidate.isAfter(day)) {
      years--;
      candidate = _monthAt(anchor, years * 12);
    }
    return candidate;
  }

  DateTime nextCycleStart(DateTime asOf) {
    final start = cycleStart(asOf);
    if (period == BudgetPeriod.weekly) {
      return start.add(const Duration(days: 7));
    }
    if (period == BudgetPeriod.fortnightly) {
      return start.add(const Duration(days: 14));
    }
    final anchor = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final count = (start.year - anchor.year) * 12 +
        start.month - anchor.month;
    return _monthAt(
      anchor,
      count + (period == BudgetPeriod.monthly ? 1 : 12),
    );
  }

  static DateTime _monthAt(DateTime anchor, int offset) {
    final first = DateTime.utc(anchor.year, anchor.month + offset, 1);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    final day = anchor.day <= lastDay ? anchor.day : lastDay;
    return DateTime.utc(first.year, first.month, day);
  }

  /// Category-level ACTUAL spending; transfers and card repayments are
  /// balance-sheet movements, not duplicate spending.
  /// Refunds reduce the category's actual expense. Loan principal is excluded.
  Map<String, int> actualSpending(
    Iterable<LedgerEntry> entries, DateTime asOf,
  ) {
    final start = cycleStart(asOf);
    final end = nextCycleStart(asOf);
    final byCategory = <String, int>{
      for (final allocation in allocations) allocation.category: 0,
    };
    final matchingCategories = {
      for (final category in byCategory.keys) category.toLowerCase(): category,
    };
    for (final entry in entries) {
      final date = DateTime.utc(entry.at.year, entry.at.month, entry.at.day);
      if (date.isBefore(start) || !date.isBefore(end)) continue;
      final category = matchingCategories[entry.category?.trim().toLowerCase()];
      if (category == null) continue;
      final amount = switch (entry.type) {
        LedgerType.cashExpense || LedgerType.cardPurchase => entry.amountCents,
        LedgerType.loanPayment => entry.interestCents,
        LedgerType.cashRefund || LedgerType.cardRefund => -entry.amountCents,
        _ => 0,
      };
      byCategory[category] = byCategory[category]! + amount;
    }
    return byCategory;
  }
}
