/// Making long numbers readable, in one place.
///
/// Written by hand rather than pulled from `intl`, which would arrive with a locale that renders
/// these in Arabic-Indic digits — the shop reads Latin ones, on a phone held at arm's length.
library;

extension GroupedDigits on int {
  /// `9651` → `9,651`.
  String get grouped {
    final digits = abs().toString();
    final buffer = StringBuffer(isNegative ? '-' : '');

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}

/// `'12450.000'` → `'12,450'`, `'1250.500'` → `'1,250.5'`.
///
/// **String surgery, never `double.parse`.** These are quantities the server sent as decimals,
/// and the decimals it chose are the decimals it means — round-tripping one through a float is
/// how `0.850` becomes `0.8500000000000001` on somebody's screen. Only the whole part is
/// grouped; a fraction is left exactly as it arrived, minus the trailing zeros a database
/// pads with.
String groupedDecimal(String value) {
  final parts = value.split('.');
  final whole = parts.first;
  final fraction = parts.length > 1
      ? parts[1].replaceFirst(RegExp(r'0+$'), '')
      : '';

  // Not `int.parse().grouped`: a value too long for an int would throw, and a quantity is never
  // worth taking a screen down for.
  final buffer = StringBuffer();
  final digits = whole.startsWith('-') ? whole.substring(1) : whole;
  if (whole.startsWith('-')) buffer.write('-');

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }

  return fraction.isEmpty ? buffer.toString() : '$buffer.$fraction';
}
