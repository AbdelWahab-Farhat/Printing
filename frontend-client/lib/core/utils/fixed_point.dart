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

/// How a decimal string from the API is **drawn**, as against how it is computed.
///
/// **Nothing above this line changes.** The arithmetic works in thousandths because a ledger
/// that shows `105,249.999` once is a ledger nobody trusts again; these two are the last step,
/// after the sums are done, and they are never fed back into one.
///
/// The API's scale is its own business and it shows: a quantity arrives as `'2000.000'` and a
/// unit price as `'1.400'`, so «٢٬٠٠٠ × ١٫٤٠ د.ل» in the design was reaching the screen as
/// «2000.000 × 1.400». Three zeros nobody typed, on the two numbers a customer checks first.
/// What the app says where a price is not known yet.
///
/// **One phrase, in one place.** An order for a product priced «حسب الطلب» carries no figure
/// until the shop quotes it, and three screens have to say so — the card, the line and the
/// total. Three literals would drift, and the one that drifted would be the one nobody read.
const String awaitingQuoteLabel = 'يُحدَّد بعد المراجعة';

extension AmountText on String {
  /// A quantity, with the API's padding taken off: `'2000.000'` → `'2,000'`, `'1.500'` → `'1.5'`.
  ///
  /// Trailing zeros only. `'1.500'` keeps its half, because half a kilo is half a kilo — what
  /// goes is the scale the column was declared at, never a digit somebody entered.
  String get asQuantity {
    final (whole, fraction) = _split(_trimmed);

    return fraction.isEmpty ? _grouped(whole) : '${_grouped(whole)}.$fraction';
  }

  /// Money, grouped, with two places or none: `'4330.00'` → `'4,330'`, `'1880.50'` →
  /// `'1,880.50'`, `'1.400'` → `'1.40'`.
  ///
  /// **The fraction is dropped only when it is nothing, and kept at two when it is not.** An
  /// amount is either a round number of dinars or it is dirhams-and-all — «١٫٤ د.ل» is the
  /// arithmetic showing through, and `'1.400'` and `'1.40'` are the same price written at two
  /// different column scales.
  ///
  /// Rounding is never done here: `'1,880.50'` stays, because turning it into `1,881` on a
  /// screen that says «المتبقّي» is the app telling somebody they owe a different amount from
  /// the one on the invoice. Anything past two places the API does not send for money.
  String get asMoney {
    final (whole, fraction) = _split(_trimmed);

    if (fraction.isEmpty) return AmountText._grouped(whole);

    return '${AmountText._grouped(whole)}.${fraction.padRight(2, '0')}';
  }

  /// The padding off and **nothing else on** — no grouping: `'100.000'` → `'100'`,
  /// `'2000.000'` → `'2000'`.
  ///
  /// **For a text field, where [asQuantity] would be a bug.** The grouping separator makes
  /// `'2,000'`, which is not a number any more: it fails the field's own `[0-9.]` formatter,
  /// and if it ever reached the wire the server would refuse the order over a comma this app
  /// put there to be helpful. Seeding a field is not drawing a label.
  String get asPlainNumber => _trimmed;

  /// `'-2000.000'` → `('-2000', '')`; the sign rides with the whole part.
  (String, String) _split(String value) {
    final point = value.indexOf('.');

    return point == -1
        ? (value, '')
        : (value.substring(0, point), value.substring(point + 1));
  }

  /// Trailing zeros after the point, and the point itself when nothing survives it.
  String get _trimmed {
    if (!contains('.')) return this;

    var end = length;
    while (end > 0 && this[end - 1] == '0') {
      end--;
    }
    if (end > 0 && this[end - 1] == '.') end--;

    return substring(0, end);
  }

  /// `'4330'` → `'4,330'`. A comma, not «٬»: the app draws Latin numerals by decision, and a
  /// Latin number with an Arabic separator in it is neither.
  static String _grouped(String whole) {
    final negative = whole.startsWith('-');
    final digits = negative ? whole.substring(1) : whole;

    if (digits.length <= 3) return whole;

    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }

    return negative ? '-$buffer' : buffer.toString();
  }
}
