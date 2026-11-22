import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_estimate.freezed.dart';

/// One size of one product on a price estimate, as the calculator hands it to the message.
///
/// A catalogue-priced line carries the server's [quote]. A product the catalogue prices
/// «حسب الطلب» has no quote; the clerk may name a price for it ([handUnitPrice]), or leave it
/// empty and the line says «السعر حسب الطلب» instead of inventing a figure.
@freezed
abstract class EstimateEntry with _$EstimateEntry {
  const factory EstimateEntry({
    required String productName,
    required String sizeLabel,

    /// What was typed, already in western digits. Shown only for a line with no [quote] —
    /// a priced line shows the server's normalised quantity instead.
    required String quantity,
    required String unitLabel,
    PriceQuote? quote,

    /// The price of one unit as the clerk typed it, in western digits — only ever set on a line
    /// with no [quote], and only once it reads as money ([parseHandPrice]).
    String? handUnitPrice,
  }) = _EstimateEntry;

  const EstimateEntry._();

  /// Whether the catalogue does not price this line — whatever the clerk did about it.
  bool get isPricedByHand => quote == null;

  String get quantityLabel => quote?.quantityLabel ?? groupedDecimal(quantity);

  /// The price of one unit, as text: the catalogue's, else the clerk's, else none.
  String? get unitPrice => quote?.unitPrice ?? handUnitPrice;

  /// What this line comes to, or null when nobody has priced it.
  String? get total => switch ((quote, handUnitPrice)) {
    (final quote?, _) => quote.total,
    (null, final price?) => handLineTotal(quantity: quantity, unitPrice: price),
    _ => null,
  };

  bool get hasPrice => total != null;
}

/// A price as the clerk typed it, made into money text — `'1,25'` → `'1.25'` — or null when it
/// is empty or is not a positive amount with at most three decimals.
String? parseHandPrice(String typed) {
  final price = typed.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(price)) return null;

  return _toMillis(price) > 0 ? price : null;
}

/// A hand-priced line's total, **by the server's own rule** — `OrderItem::deriveLineTotal`
/// through `Money::wholeDinars`: quantity × unit price, the fraction of a dinar dropped, and a
/// line worth something never shown as zero (it becomes one dinar).
///
/// Kept in step with the server on purpose: this is the figure the order will carry if the
/// customer goes ahead, and a calculator that rounds differently quotes one number and invoices
/// another. Returns null when the quantity is not a number.
String? handLineTotal({required String quantity, required String unitPrice}) {
  final quantityText = quantity.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(quantityText)) return null;

  // Both in thousandths, so the product is in millionths of a dinar.
  final micro = _toMillis(quantityText) * _toMillis(unitPrice);
  var whole = micro ~/ 1000000;
  if (whole == 0 && micro > 0) whole = 1;

  return _fromMillis(whole * 1000);
}

/// The sum of every priced line, as the server writes money: three decimals, as text.
///
/// **Added in thousandths of a dinar, never as `double`.** `0.1 + 0.2` is not `0.3` in binary
/// floating point, and a quoted total read out to a customer is the last place for that to
/// show. Returns null when nothing on the estimate has a price.
String? estimateTotal(List<EstimateEntry> entries) {
  final priced = [for (final entry in entries) ?entry.total];
  if (priced.isEmpty) return null;

  final millis = priced.fold<int>(0, (sum, total) => sum + _toMillis(total));

  return _fromMillis(millis);
}

/// The text the clerk pastes to the customer: each product, then each of its sizes with the
/// count, the price of one, and what that size comes to — and the total at the end.
///
/// Sizes are grouped under their product in the order the product was first added, which is
/// the order the customer asked for them in.
String priceEstimateMessage(List<EstimateEntry> entries) {
  final byProduct = <String, List<EstimateEntry>>{};
  for (final entry in entries) {
    byProduct.putIfAbsent(entry.productName, () => []).add(entry);
  }

  final buffer = StringBuffer('مرحباً، هذا عرض السعر المطلوب:\n');

  for (final MapEntry(key: product, value: sizes) in byProduct.entries) {
    buffer
      ..writeln()
      ..writeln(product);

    for (final size in sizes) {
      final head = '• ${_sizeText(size.sizeLabel)} — ${size.quantityLabel} ${size.unitLabel}';

      buffer.writeln(switch ((size.unitPrice, size.total)) {
        (final price?, final total?) =>
          '$head × ${groupedDecimal(price)} = ${groupedDecimal(total)} د.ل',
        _ => '$head — السعر حسب الطلب',
      });
    }
  }

  final total = estimateTotal(entries);
  final hasUnpriced = entries.any((entry) => !entry.hasPrice);

  buffer.writeln();
  if (total != null) {
    buffer.writeln('الإجمالي: ${groupedDecimal(total)} د.ل');
    if (hasUnpriced) buffer.writeln('(لا يشمل الأصناف المسعّرة حسب الطلب)');
  }
  buffer.write('الأسعار لا تشمل التوصيل.');

  return buffer.toString();
}

/// «مقاس 25*35» for a size given as dimensions, the label alone for one that is a word —
/// «مقاس سادة» reads as a mistake.
String _sizeText(String label) =>
    RegExp(r'^[0-9٠-٩]').hasMatch(label.trim()) ? 'مقاس $label' : label;

/// `'475.000'` → `475000`. The server always sends three decimals or fewer; anything past the
/// third is dropped rather than rounded, because there is nothing past it to round.
int _toMillis(String amount) {
  final negative = amount.startsWith('-');
  final digits = negative ? amount.substring(1) : amount;
  final [whole, ...rest] = digits.split('.');
  final fraction = (rest.isEmpty ? '' : rest.first).padRight(3, '0').substring(0, 3);
  final value = int.parse(whole.isEmpty ? '0' : whole) * 1000 + int.parse(fraction);

  return negative ? -value : value;
}

String _fromMillis(int millis) {
  final sign = millis < 0 ? '-' : '';
  final absolute = millis.abs();

  return '$sign${absolute ~/ 1000}.${(absolute % 1000).toString().padLeft(3, '0')}';
}
