import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/app/tong_ledger_app.dart';

void main() {
  testWidgets('first screen is clearly marked as unsaved demo', (tester) async {
    await tester.pumpWidget(const TongLedgerApp());
    expect(find.text('TONG LEDGER'), findsOneWidget);
    expect(find.text('DEMO • NOT SAVED • DO NOT ENTER REAL DATA'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
