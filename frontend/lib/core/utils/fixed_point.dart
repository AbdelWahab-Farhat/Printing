/// Exact arithmetic on the decimal strings the API sends.
///
/// Quantities arrive as `'1000.000'` and money as `'3.500'` or `'1050.00'`, and a screen that
/// adds or multiplies them must not do so in `double`: `105250.000 - 300.000` is fine, but
/// `0.1 + 0.2` is not, and a ledger that shows `105,249.999` once is a ledger nobody trusts
/// again. Everything here works in thousandths as [BigInt] — three places is the finest scale
/// the API uses — and formats back to a fixed scale at the very end.
library;

/// `'1050.25'` → `1050250`; `'-300'` → `-300000`. Anything past three places is truncated,
/// which never happens with what the API sends.
BigInt thousandths(String value) {
  final negative = value.startsWith('-');
  final unsigned = negative ? value.substring(1) : value;
  final point = unsigned.indexOf('.');
  final whole = point == -1 ? unsigned : unsigned.substring(0, point);
  final fraction = (point == -1 ? '' : unsigned.substring(point + 1)).padRight(3, '0').substring(0, 3);
  final magnitude = BigInt.parse('${whole.isEmpty ? '0' : whole}$fraction');

  return negative ? -magnitude : magnitude;
}

/// The inverse of [thousandths], at [scale] decimal places (0–3). Rounds half away from zero.
String fromThousandths(BigInt value, {int scale = 3}) {
  assert(scale >= 0 && scale <= 3, 'thousandths carry three places, not $scale');

  final divisor = BigInt.from(10).pow(3 - scale);
  final half = divisor ~/ BigInt.two;
  final negative = value.isNegative;
  final rounded = ((negative ? -value : value) + half) ~/ divisor;
  final digits = rounded.toString().padLeft(scale + 1, '0');
  final whole = digits.substring(0, digits.length - scale);
  final fraction = digits.substring(digits.length - scale);
  final text = scale == 0 ? whole : '$whole.$fraction';

  return negative && rounded != BigInt.zero ? '-$text' : text;
}

/// `quantity × unitCost`, both decimal strings, as money to two places.
String multiplyToMoney(String quantity, String unitCost) {
  // thousandths × thousandths = millionths; back to thousandths first.
  final product = thousandths(quantity) * thousandths(unitCost);
  final asThousandths = _roundedDivide(product, BigInt.from(1000));

  return fromThousandths(asThousandths, scale: 2);
}

/// `money ÷ quantity` as a unit cost to three places, or null when there is nothing to divide by.
String? divideToUnitCost(String money, String quantity) {
  final divisor = thousandths(quantity);
  if (divisor == BigInt.zero) return null;

  // (money in thousandths × 1000) ÷ (quantity in thousandths) = unit cost in thousandths.
  return fromThousandths(_roundedDivide(thousandths(money) * BigInt.from(1000), divisor));
}

/// `a + b` on decimal strings, at three places.
String addDecimals(String a, String b) => fromThousandths(thousandths(a) + thousandths(b));

/// `a − b` on decimal strings, at three places.
String subtractDecimals(String a, String b) => fromThousandths(thousandths(a) - thousandths(b));

BigInt _roundedDivide(BigInt value, BigInt divisor) {
  final negative = value.isNegative != divisor.isNegative;
  final magnitude = ((value.abs() * BigInt.two) + divisor.abs()) ~/ (divisor.abs() * BigInt.two);

  return negative ? -magnitude : magnitude;
}
