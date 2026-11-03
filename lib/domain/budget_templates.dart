/// Immutable seed data: 30 real budget allocation plans, six groups of five.
/// Plans do not create or change any account balances.
class BudgetTemplate {
  const BudgetTemplate({
    required this.id,
    required this.group,
    required this.name,
    required this.allocations,
  });

  final String id;
  final String group;
  final String name;
  final Map<String, int> allocations;

  int get totalPercent => allocations.values.fold(0, (sum, item) => sum + item);

  /// Returns category amounts in *integer cents*. Remainder is assigned to
  /// the last category so the exact amounts always sum to the given income.
  Map<String, int> amountsFor(int incomeCents) {
    if (incomeCents < 0) throw ArgumentError.value(incomeCents, 'incomeCents');
    if (totalPercent != 100 || allocations.isEmpty) {
      throw StateError('Budget template percentages must total 100.');
    }
    final result = <String, int>{};
    var assigned = 0;
    final categories = allocations.entries.toList();
    for (var i = 0; i < categories.length; i++) {
      final item = categories[i];
      final amount = i == categories.length - 1
          ? incomeCents - assigned
          : (incomeCents * item.value) ~/ 100;
      result[item.key] = amount;
      assigned += amount;
    }
    return result;
  }
}

const budgetTemplates = <BudgetTemplate>[
  BudgetTemplate(
    id: 'plan_01',
    group: 'Students & Youth',
    name: 'Teen Starter',
    allocations: <String, int>{'Essentials': 20, 'Learning': 10, 'Transport': 10, 'Lifestyle': 20, 'Short-term savings': 20, 'Long-term savings': 20},
  ),
  BudgetTemplate(
    id: 'plan_02',
    group: 'Students & Youth',
    name: 'Shared-Rent Student',
    allocations: <String, int>{'Housing': 35, 'Groceries': 20, 'Transport': 10, 'Education': 10, 'Bills': 5, 'Emergency': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_03',
    group: 'Students & Youth',
    name: 'Living at Home',
    allocations: <String, int>{'Family contribution': 10, 'Groceries': 10, 'Transport': 15, 'Education': 15, 'Savings': 35, 'Lifestyle': 15},
  ),
  BudgetTemplate(
    id: 'plan_04',
    group: 'Students & Youth',
    name: 'International Student',
    allocations: <String, int>{'Housing': 40, 'Groceries': 18, 'Transport': 10, 'Tuition': 12, 'Bills': 8, 'Emergency': 7, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_05',
    group: 'Students & Youth',
    name: 'Apprentice',
    allocations: <String, int>{'Housing': 25, 'Groceries': 15, 'Transport': 15, 'Tools': 10, 'Bills': 10, 'Emergency': 15, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_06',
    group: 'Salary & Careers',
    name: 'First Job',
    allocations: <String, int>{'Housing': 30, 'Groceries': 15, 'Transport': 10, 'Bills': 10, 'Emergency': 15, 'Investing': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_07',
    group: 'Salary & Careers',
    name: 'Weekly Pay',
    allocations: <String, int>{'Housing': 30, 'Groceries': 15, 'Transport': 12, 'Bills': 8, 'Savings': 15, 'Debt payments': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_08',
    group: 'Salary & Careers',
    name: 'Fortnightly Pay',
    allocations: <String, int>{'Housing': 32, 'Groceries': 14, 'Transport': 12, 'Bills': 12, 'Savings': 15, 'Debt payments': 5, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_09',
    group: 'Salary & Careers',
    name: 'Salary Growth',
    allocations: <String, int>{'Housing': 28, 'Groceries': 13, 'Transport': 10, 'Bills': 9, 'Savings': 25, 'Investing': 10, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_10',
    group: 'Salary & Careers',
    name: 'High Income Disciplined',
    allocations: <String, int>{'Housing': 25, 'Groceries': 12, 'Transport': 8, 'Bills': 10, 'Investing': 25, 'Savings': 15, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_11',
    group: 'Couples & Families',
    name: 'New Couple',
    allocations: <String, int>{'Housing': 35, 'Groceries': 18, 'Transport': 12, 'Bills': 10, 'Savings': 15, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_12',
    group: 'Couples & Families',
    name: 'Young Family',
    allocations: <String, int>{'Housing': 35, 'Groceries': 20, 'Childcare': 10, 'Transport': 10, 'Bills': 10, 'Savings': 10, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_13',
    group: 'Couples & Families',
    name: 'Single Parent',
    allocations: <String, int>{'Housing': 40, 'Groceries': 20, 'Childcare': 10, 'Transport': 10, 'Bills': 10, 'Emergency': 7, 'Lifestyle': 3},
  ),
  BudgetTemplate(
    id: 'plan_14',
    group: 'Couples & Families',
    name: 'Large Household',
    allocations: <String, int>{'Housing': 35, 'Groceries': 25, 'Transport': 12, 'Bills': 12, 'Savings': 10, 'Lifestyle': 6},
  ),
  BudgetTemplate(
    id: 'plan_15',
    group: 'Couples & Families',
    name: 'Homeowner Household',
    allocations: <String, int>{'Mortgage': 35, 'Groceries': 15, 'Transport': 12, 'Bills': 12, 'Home upkeep': 8, 'Savings': 12, 'Lifestyle': 6},
  ),
  BudgetTemplate(
    id: 'plan_16',
    group: 'Variable Income',
    name: 'Freelancer',
    allocations: <String, int>{'Housing': 25, 'Groceries': 15, 'Bills': 10, 'Tax reserve': 20, 'Emergency': 15, 'Business costs': 10, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_17',
    group: 'Variable Income',
    name: 'Sole Trader',
    allocations: <String, int>{'Business costs': 25, 'Tax reserve': 20, 'Housing': 20, 'Groceries': 10, 'Bills': 10, 'Savings': 10, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_18',
    group: 'Variable Income',
    name: 'Shift Worker',
    allocations: <String, int>{'Housing': 30, 'Groceries': 15, 'Transport': 15, 'Bills': 10, 'Savings': 20, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_19',
    group: 'Variable Income',
    name: 'Seasonal Worker',
    allocations: <String, int>{'Essentials': 40, 'Tax reserve': 15, 'Emergency': 25, 'Sinking funds': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_20',
    group: 'Variable Income',
    name: 'Multiple Incomes',
    allocations: <String, int>{'Essentials': 45, 'Savings': 20, 'Investing': 15, 'Goals': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_21',
    group: 'Goals & Debt',
    name: 'Emergency First',
    allocations: <String, int>{'Essentials': 50, 'Debt payments': 15, 'Emergency': 25, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_22',
    group: 'Goals & Debt',
    name: 'Debt Avalanche',
    allocations: <String, int>{'Essentials': 55, 'Minimum repayments': 15, 'Extra debt': 20, 'Emergency': 5, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_23',
    group: 'Goals & Debt',
    name: 'Debt Snowball',
    allocations: <String, int>{'Essentials': 55, 'Minimum repayments': 15, 'Extra debt': 15, 'Emergency': 10, 'Lifestyle': 5},
  ),
  BudgetTemplate(
    id: 'plan_24',
    group: 'Goals & Debt',
    name: 'House Deposit',
    allocations: <String, int>{'Essentials': 50, 'Deposit savings': 30, 'Emergency': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_25',
    group: 'Goals & Debt',
    name: 'Travel Goal',
    allocations: <String, int>{'Essentials': 55, 'Travel fund': 20, 'Savings': 15, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_26',
    group: 'Lifestyle & Milestones',
    name: 'Frugal Living',
    allocations: <String, int>{'Essentials': 50, 'Savings': 25, 'Investing': 15, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_27',
    group: 'Lifestyle & Milestones',
    name: 'Balanced 50/30/20',
    allocations: <String, int>{'Needs': 50, 'Wants': 30, 'Savings': 20},
  ),
  BudgetTemplate(
    id: 'plan_28',
    group: 'Lifestyle & Milestones',
    name: 'Zero-Based Starter',
    allocations: <String, int>{'Housing': 32, 'Groceries': 18, 'Transport': 12, 'Bills': 12, 'Savings': 16, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_29',
    group: 'Lifestyle & Milestones',
    name: 'Retirement Transition',
    allocations: <String, int>{'Housing': 30, 'Groceries': 15, 'Health': 15, 'Bills': 10, 'Emergency': 10, 'Investing': 10, 'Lifestyle': 10},
  ),
  BudgetTemplate(
    id: 'plan_30',
    group: 'Lifestyle & Milestones',
    name: 'New Arrival',
    allocations: <String, int>{'Housing': 35, 'Groceries': 18, 'Transport': 12, 'Setup costs': 15, 'Emergency': 15, 'Lifestyle': 5},
  ),
];

List<String> get budgetCollections =>
    budgetTemplates.map((e) => e.group).toSet().toList(growable: false);
