// Keep the SDK Material import until a cross-platform migration is tested.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'app/tong_ledger_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TongLedgerApp());
}
