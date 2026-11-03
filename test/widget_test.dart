import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/app/tong_ledger_app.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/storage/finance_book_codec.dart';
import 'package:tong_ledger/storage/finance_store.dart';

class FakeFinanceStore implements FinanceStore {
  FinanceBook data = FinanceBook();
  int saves = 0;

  @override
  Future<FinanceBook> load() async =>
      FinanceBookCodec.decode(FinanceBookCodec.encode(data));

  @override
  Future<void> save(FinanceBook book) async {
    data = FinanceBookCodec.decode(FinanceBookCodec.encode(book));
    saves++;
  }
}

void main() {
  testWidgets('starts with empty local vault and usable bottom navigation',
      (tester) async {
    final store = FakeFinanceStore();
    await tester.pumpWidget(TongLedgerApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('TONG LEDGER'), findsOneWidget);
    expect(find.text('PRIVATE LOCAL VAULT • BETA • VERIFY YOUR BACKUP'),
        findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(store.saves, 0);
  });

  testWidgets('demo mode does not mutate real local records', (tester) async {
    final store = FakeFinanceStore();
    await tester.pumpWidget(TongLedgerApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore fictional demo'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO • FICTIONAL • NOT SAVED'), findsOneWidget);
    expect(store.data.accounts, isEmpty);
    expect(store.saves, 0);
  });
  testWidgets('custom budget can be saved independently in the local vault',
      (tester) async {
    final store = FakeFinanceStore();
    await tester.pumpWidget(TongLedgerApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create custom budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget Editor'), findsOneWidget);
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(store.saves, 1);
    expect(store.data.budgets, hasLength(1));
    expect(store.data.budgets.single.name, 'My Custom Budget');
    expect(find.text('My Custom Budget'), findsWidgets);
  });

  testWidgets('account editing preserves posted financial balance',
      (tester) async {
    final store = FakeFinanceStore();
    store.data.institutions.add(const Institution(id: 'bank1', name: 'Bank One'));
    store.data.accounts.add(const CashAccount(
      id: 'cash', name: 'Everyday', openingCents: 10000,
      institutionId: 'bank1',
    ));
    store.data.entries.add(LedgerEntry(
      id: 'txn', type: LedgerType.cashExpense, amountCents: 1000,
      sourceAccountId: 'cash', at: DateTime.utc(2026, 11, 3),
      category: 'Food',
    ));
    await tester.pumpWidget(TongLedgerApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Money').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();
    expect(find.text('Opening balance (AUD)'), findsNothing);
    expect(find.text('Account nickname'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'Main Spending');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(store.data.accounts.single.name, 'Main Spending');
    expect(store.data.accounts.single.openingCents, 10000);
    expect(store.data.entries.single.amountCents, 1000);
  });

}
