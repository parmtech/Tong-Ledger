import 'dart:convert';

import '../domain/finance_models.dart';
import '../domain/budget_plan.dart';
import '../domain/ledger_engine.dart';

/// Versioned strict snapshot codec; decoded JSON must only live in memory.
class FinanceBookCodec {
  static const schemaVersion = 1;

  static String encode(FinanceBook book) => jsonEncode({
        'schema': schemaVersion,
        'selectedTemplateId': book.selectedBudgetTemplateId,
        'institutions': [
          for (final a in book.institutions)
            {'id': a.id, 'name': a.name, 'kind': a.kind},
        ],
        'accounts': [
          for (final a in book.accounts)
            {
              'id': a.id, 'name': a.name, 'institutionId': a.institutionId,
              'kind': a.kind.name, 'openingCents': a.openingCents,
            },
        ],
        'cards': [
          for (final a in book.cards)
            {
              'id': a.id, 'name': a.name, 'institutionId': a.institutionId,
              'limitCents': a.limitCents, 'openingOwedCents': a.openingOwedCents,
            },
        ],
        'loans': [
          for (final a in book.loans)
            {
              'id': a.id, 'name': a.name, 'lenderName': a.lenderName,
              'institutionId': a.institutionId, 'kind': a.kind,
              'openingOutstandingCents': a.openingOutstandingCents,
              'instalmentCents': a.instalmentCents,
            },
        ],
        'assets': [
          for (final a in book.assets)
            {
              'id': a.id, 'name': a.name, 'valuationCents': a.valuationCents,
              'asOf': a.asOf.toUtc().toIso8601String(),
            },
        ],
        'incomeSources': [
          for (final a in book.incomeSources)
            {
              'id': a.id, 'name': a.name, 'expectedCents': a.expectedCents,
              'cadence': a.cadence,
              'destinationAccountId': a.destinationAccountId,
            },
        ],
        'budgets': [
          for (final plan in book.budgets)
            {
              'id': plan.id,
              'name': plan.name,
              'period': plan.period.name,
              'startDate': DateTime.utc(
                plan.startDate.year, plan.startDate.month, plan.startDate.day,
              ).toIso8601String(),
              'incomeCents': plan.incomeCents,
              'templateId': plan.templateId,
              'allocations': [
                for (final category in plan.allocations)
                  {
                    'category': category.category,
                    'plannedCents': category.plannedCents,
                  },
              ],
            },
        ],
        'entries': [
          for (final e in book.entries)
            {
              'id': e.id, 'type': e.type.name, 'amountCents': e.amountCents,
              'at': e.at.toUtc().toIso8601String(),
              'sourceAccountId': e.sourceAccountId,
              'destinationAccountId': e.destinationAccountId,
              'cardId': e.cardId, 'loanId': e.loanId,
              'interestCents': e.interestCents, 'category': e.category,
            },
        ],
      });

  static FinanceBook decode(String encoded) {
    if (encoded.length > 8 * 1024 * 1024) {
      throw const FormatException('Finance snapshot is too large.');
    }
    final data = (jsonDecode(encoded) as Map).cast<String, dynamic>();
    if (data['schema'] != schemaVersion) {
      throw const FormatException('Unsupported finance file schema.');
    }
    Map<String, dynamic> record(dynamic value) =>
        (value as Map).cast<String, dynamic>();
    List<T> read<T>(String field, T Function(Map<String, dynamic>) decode) {
      final list = data[field] as List<dynamic>;
      if (list.length > 100000) {
        throw const FormatException('Too many records in finance file.');
      }
      return list.map((value) => decode(record(value))).toList();
    }

    final book = FinanceBook(
      selectedBudgetTemplateId: data['selectedTemplateId'] as String?,
      institutions: read('institutions', (r) => Institution(
        id: r['id'] as String, name: r['name'] as String,
        kind: r['kind'] as String,
      )),
      accounts: read('accounts', (r) => CashAccount(
        id: r['id'] as String, name: r['name'] as String,
        institutionId: r['institutionId'] as String?,
        kind: AccountKind.values.byName(r['kind'] as String),
        openingCents: r['openingCents'] as int,
      )),
      cards: read('cards', (r) => CreditCardAccount(
        id: r['id'] as String, name: r['name'] as String,
        institutionId: r['institutionId'] as String?,
        limitCents: r['limitCents'] as int,
        openingOwedCents: r['openingOwedCents'] as int,
      )),
      loans: read('loans', (r) => LoanAccount(
        id: r['id'] as String, name: r['name'] as String,
        lenderName: r['lenderName'] as String,
        institutionId: r['institutionId'] as String?,
        kind: r['kind'] as String,
        openingOutstandingCents: r['openingOutstandingCents'] as int,
        instalmentCents: r['instalmentCents'] as int?,
      )),
      assets: read('assets', (r) => AssetRecord(
        id: r['id'] as String, name: r['name'] as String,
        valuationCents: r['valuationCents'] as int,
        asOf: DateTime.parse(r['asOf'] as String),
      )),
      incomeSources: read('incomeSources', (r) => IncomeSource(
        id: r['id'] as String, name: r['name'] as String,
        expectedCents: r['expectedCents'] as int,
        cadence: r['cadence'] as String,
        destinationAccountId: r['destinationAccountId'] as String?,
      )),
      budgets: [
        // Schema v1 had no custom budget plans. Default to an empty list for
        // backwards-compatible encrypted vault upgrades.
        for (final raw in (data['budgets'] as List<dynamic>? ?? const []))
          BudgetPlan(
            id: record(raw)['id'] as String,
            name: record(raw)['name'] as String,
            period: BudgetPeriod.values.byName(
              record(raw)['period'] as String,
            ),
            startDate: DateTime.parse(record(raw)['startDate'] as String),
            incomeCents: record(raw)['incomeCents'] as int,
            templateId: record(raw)['templateId'] as String?,
            allocations: [
              for (final item in record(raw)['allocations'] as List<dynamic>)
                BudgetAllocation(
                  category: record(item)['category'] as String,
                  plannedCents: record(item)['plannedCents'] as int,
                ),
            ],
          ),
      ],
      entries: read('entries', (r) => LedgerEntry(
        id: r['id'] as String, type: LedgerType.values.byName(r['type'] as String),
        amountCents: r['amountCents'] as int, at: DateTime.parse(r['at'] as String),
        sourceAccountId: r['sourceAccountId'] as String?,
        destinationAccountId: r['destinationAccountId'] as String?,
        cardId: r['cardId'] as String?, loanId: r['loanId'] as String?,
        interestCents: r['interestCents'] as int,
        category: r['category'] as String?,
      )),
    );

    final idsByCollection = <List<String>>[
      book.institutions.map((e) => e.id).toList(),
      book.accounts.map((e) => e.id).toList(),
      book.cards.map((e) => e.id).toList(),
      book.loans.map((e) => e.id).toList(),
      book.assets.map((e) => e.id).toList(),
      book.incomeSources.map((e) => e.id).toList(),
      book.entries.map((e) => e.id).toList(),
      book.budgets.map((e) => e.id).toList(),
    ];
    for (final ids in idsByCollection) {
      if (ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
        throw const FormatException('Duplicate or empty record identifier.');
      }
    }
    for (final plan in book.budgets) {
      plan.validate();
    }
    calculateLedger(book);
    return book;
  }
}
