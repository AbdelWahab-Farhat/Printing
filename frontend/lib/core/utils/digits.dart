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
  /// `'2975.00'` → `'2,975.00'`, `'0.850'` → `'0.850'`.
  ///
  /// **String surgery, never `double.parse`.** These are amounts the server sent as decimals,
  /// and the decimals it chose are the decimals it means — round-tripping one through a float is
  /// how `0.850` becomes `0.8500000000000001` on somebody's screen. Only the whole part is
  /// grouped; the fraction is left exactly as it arrived, so this can be applied to anything on
  /// screen without also deciding how precise it should look.
  String get grouped {
    final point = indexOf('.');
    if (point == -1) return _groupWhole(this);

    return '${_groupWhole(substring(0, point))}${substring(point)}';
  }
}

/// `'12450.000'` → `'12,450'`, `'1250.500'` → `'1,250.5'`.
///
/// For a figure going to a widget: the padding zeros are noise to a person, and the separator is
/// what makes the rest legible.
String groupedDecimal(String value) => trimDecimals(value).grouped;

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
