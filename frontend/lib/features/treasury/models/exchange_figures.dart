/// «صرف عملة»'s third figure from the two typed — the server's `ExchangeRate::figures()`, in
/// fixed point. USD-ACCOUNTS §٣.
///
/// **Never a `double`.** Amounts are whole dirhams or cents and the rate whole ten-thousandths,
/// held in [BigInt]; what is worked out is rounded half up, to the cent or to four places — the
/// way the server rounds, so the figure on the screen is the one that gets written.
library;

final _cents = BigInt.from(100);
final _tenThousandths = BigInt.from(10000);

/// `'7150'` → 715000 at [scale] 100; null for anything that is not a plain positive decimal
/// with no more places than the scale allows.
BigInt? _fixed(String? text, BigInt scale) {
  final value = (text ?? '').trim();
  final places = scale.toString().length - 1;

  if (!RegExp('^\\d+(\\.\\d{0,$places})?\$').hasMatch(value)) return null;

  final parts = value.split('.');
  final fraction = (parts.length > 1 ? parts[1] : '').padRight(places, '0');
  final fixed = BigInt.parse(parts[0]) * scale + BigInt.parse(fraction.isEmpty ? '0' : fraction);

  return fixed > BigInt.zero ? fixed : null;
}

/// [numerator] / [denominator], rounded half up — both positive.
BigInt _divide(BigInt numerator, BigInt denominator) =>
    (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);

String _text(BigInt fixed, BigInt scale) {
  final places = scale.toString().length - 1;
  final whole = fixed ~/ scale;
  final fraction = (fixed % scale).toString().padLeft(places, '0');

  return '$whole.$fraction';
}

/// Fills in whichever of [lyd], [usd] and [rate] is not in [typed], from the two that are.
///
/// [typed] names the two the person typed, by `'lyd'`, `'usd'` or `'rate'`. Anything else — one
/// figure, a figure that is not a number, a third that would round to nothing — leaves the
/// missing one null.
String? completeExchange({
  required Set<String> typed,
  required String? lyd,
  required String? usd,
  required String? rate,
}) {
  final dinars = _fixed(lyd, _cents);
  final dollars = _fixed(usd, _cents);
  final perDollar = _fixed(rate, _tenThousandths);

  final worked = switch (typed) {
    final t when t.containsAll({'lyd', 'usd'}) && dinars != null && dollars != null => _text(
      _divide(dinars * _tenThousandths, dollars),
      _tenThousandths,
    ),
    final t when t.containsAll({'lyd', 'rate'}) && dinars != null && perDollar != null => _text(
      _divide(dinars * _tenThousandths, perDollar),
      _cents,
    ),
    final t when t.containsAll({'usd', 'rate'}) && dollars != null && perDollar != null => _text(
      _divide(dollars * perDollar, _tenThousandths),
      _cents,
    ),
    _ => null,
  };

  // 0.01 dinars at a rate of seven is no cent at all; the server refuses it, so say nothing.
  return worked == null || RegExp(r'^0\.0+$').hasMatch(worked) ? null : worked;
}
