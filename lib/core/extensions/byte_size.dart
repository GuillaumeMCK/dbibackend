import '/i18n/i18n.g.dart';

extension ByteSize on int {
  /// This many bytes, in the largest binary unit that keeps them above 1,
  /// with the current locale's units and decimal separator: `1.5 MB`,
  /// `1,5 Mo`.
  String get bytes {
    final units = t.units.bytes;
    var value = toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final number = value
        .toStringAsFixed(unit == 0 ? 0 : 1)
        .replaceFirst('.', t.units.decimalSeparator);
    return '$number ${units[unit]}';
  }
}
