/// Making long numbers readable, in one place.
///
/// **Every number the app draws goes through here.** `2975` is read as a shape, `2,975` as a
/// number, and a total that groups on one screen and does not on the next reads as two different
/// figures. So the separator is a standard, not a decision taken per widget.
///
/// Three jobs, kept apart on purpose:
///
///   * [GroupedDigits.grouped] / [GroupedNumberText.grouped] — **add separators, change nothing
///     else.** The fraction the server sent is the fraction it means.
///   * [trimDecimals] — **drop the zeros a database pads with, add no separators.** This is the
///     one that goes back into a text field, where a comma would be read as a decimal point on
///     an Arabic keyboard.
///   * [groupedDecimal] — the two of them, in that order, for a figure headed straight to a
///     widget.
///
/// Written by hand rather than pulled from `intl`, which would arrive with a locale that renders
/// these in Arabic-Indic digits — the shop reads Latin ones, on a phone held at arm's length.
///
/// **A grouped number wants `textDirection: TextDirection.ltr` when it is drawn on its own**, or
/// the RTL layout around it can land the separator on the wrong side.
library;

extension GroupedDigits on int {
  /// `9651` → `9,651`.
  String get grouped => _groupWhole(toString());
}

extension GroupedNumberText on String {
  /// `'2975.00'` → `'2,975'`, `'0.850'` → `'0.85'`, `'1250.500'` → `'1,250.5'`.
  ///
  /// **String surgery, never `double.parse`.** These are amounts the server sent as decimals,
  /// and round-tripping one through a float is how `0.850` becomes `0.8500000000000001` on
  /// somebody's screen.
  ///
  /// **The padding zeros are cut, and that is a display decision made once here.** The server
  /// sends `100000.00` because two places is what money is stored in; a person reading a screen
  /// wants «100,000». Doing it at the single place every figure passes through is what keeps one
  /// screen from disagreeing with the next — the alternative was ninety call sites each choosing.
  ///
  /// Not for a text field's initial value: use [trimDecimals] there, because a separator comes
  /// back through `Validators.toWesternDigits` as a decimal point.
  String get grouped {
    final trimmed = trimDecimals(this);
    final point = trimmed.indexOf('.');

    if (point == -1) return _groupWhole(trimmed);

    return '${_groupWhole(trimmed.substring(0, point))}${trimmed.substring(point)}';
  }
}

/// `'12450.000'` → `'12,450'`, `'1250.500'` → `'1,250.5'`.
///
/// Kept as a name for what [GroupedNumberText.grouped] now does on its own, because «هذا رقم
/// عشري» reads at a call site and the two were never allowed to differ.
String groupedDecimal(String value) => value.grouped;

/// The size of a figure, with the sign taken off — `'-1500.00'` → `'1500.00'`.
///
/// **For a number whose direction is already said in a word.** «خسارة -1,500 د.ل» says it twice
/// and reads as a negative loss, which is a profit; «خسارة 1,500 د.ل» is what a person means.
/// Only ever paired with that word — a bare figure that has quietly dropped its minus is worse
/// than either.
String unsigned(String value) => value.startsWith('-') ? value.substring(1) : value;

/// `'100.000'` → `'100'`, `'0.850'` → `'0.85'`.
///
/// String surgery, not `double.parse().toString()`: the decimals the server chose to send are
/// the decimals it means, and round-tripping them through a float loses that.
///
/// **No separators**, because this is also what prefills a text field — and a comma there comes
/// back through `Validators.toWesternDigits` as a decimal point.
String trimDecimals(String value) {
  if (!value.contains('.')) return value;

  final trimmed = value.replaceFirst(RegExp(r'0+$'), '');

  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}

/// Separators every three digits from the right, minus sign left outside.
///
/// Not `int.parse().grouped`: a value too long for an int would throw, and a quantity is never
/// worth taking a screen down for. Anything that is not a run of digits — an em dash, an empty
/// string — passes through untouched, because a widget that has nothing to draw should draw
/// nothing rather than throw.
String _groupWhole(String whole) {
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;
  if (digits.isEmpty || !_digitsOnly.hasMatch(digits)) return whole;

  final buffer = StringBuffer(isNegative ? '-' : '');

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }

  return buffer.toString();
}

final RegExp _digitsOnly = RegExp(r'^\d+$');
