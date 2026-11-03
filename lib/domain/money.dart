/// Fixed-point currency utilities, using AUD minor units (cents).
/// Future currencies with different ISO exponents require separate handling.
class Money {
  const Money(this.cents);
  final int cents;

  static Money? tryParse(String raw) {
    final value = raw.trim().replaceAll(',', '').replaceAll(r'$', '');
    if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(value)) return null;
    final negative = value.startsWith('-');
    final unsigned = negative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    try {
      final whole = int.parse(parts[0]);
      final fractional = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
      final result = whole * 100 + fractional;
      return Money(negative ? -result : result);
    } on FormatException {
      return null;
    }
  }

  String get aud {
    final negative = cents < 0;
    final magnitude = negative ? -cents : cents;
    final integerPart = (magnitude ~/ 100).toString();
    final fraction = (magnitude % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(integerPart[i]);
    }
    return '${negative ? '-' : ''}A\$${buffer.toString()}.$fraction';
  }

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);

  @override
  String toString() => aud;
}
