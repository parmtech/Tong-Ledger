import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/money.dart';

void main() {
  test('money parse uses cents without floats', () {
    expect(Money.tryParse('1,234.50')?.cents, 123450);
    expect(Money.tryParse('0.1')?.cents, 10);
    expect(Money.tryParse('-12.30')?.cents, -1230);
    expect(Money.tryParse('1.234'), isNull);
    expect(Money.tryParse('abc'), isNull);
  });
  test('AUD display shows separators, minus and cents', () {
    expect(const Money(123450).aud, r'A$1,234.50');
    expect(const Money(-150).aud, r'-A$1.50');
    expect(const Money(0).aud, r'A$0.00');
  });
}
