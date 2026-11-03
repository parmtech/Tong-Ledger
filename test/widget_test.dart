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

class FakeLockedVault implements RecoverableFinanceStore {
  @override
  Future<FinanceBook> load() async => throw StateError('Simulated missing key');

  @override
  Future<void> save(FinanceBook book) async =>
      throw StateError('Cannot save locked vault');

  @override
  Future<void> restoreVerifiedBackup(FinanceBook restored) async {}
}

void main() {
  testWidgets('starts with empty local vault and usable bottom navigation',
      (tester) async {
    final store = FakeFinanceStore();
    await tester.pumpWidget(TongLedgerApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('TONG LEDGER'), findsOneWidget);
    expect(find.text('PRIVATE LOCAL VAULT • BETA • BACKUP TESTING ONLY'),
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

  testWidgets('locked vault opens password-protected recovery-only screen',
      (tester) async {
    await tester.pumpWidget(TongLedgerApp(store: FakeLockedVault()));
    await tester.pumpAndSettle();

    expect(find.text('Recover from encrypted backup'), findsOneWidget);
    await tester.tap(find.text('Recover from encrypted backup'));
    await tester.pumpAndSettle();
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Select encrypted backup'), findsOneWidget);
    expect(find.text('Save .tlbackup file'), findsNothing);
  });


}
