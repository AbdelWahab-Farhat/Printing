part of 'order_invoice_cubit.dart';

/// One editable line of the invoice.
///
/// `unitPrice` is carried to be *shown*, never sent: the server re-prices every line from the
/// catalogue on save, which is what stops an edit quietly undercutting an agreed rate.
@freezed
abstract class InvoiceLine with _$InvoiceLine {
  const factory InvoiceLine({
    required int id,
    required int productId,
    required int variantId,
    required String productName,
    required String variantLabel,
    required String pricingUnitLabel,
    required String unitPrice,
    required String quantity,
  }) = _InvoiceLine;

  const InvoiceLine._();

  /// Whether the typed quantity is a number the server would accept.
  bool get hasValidQuantity {
    final parsed = double.tryParse(_ascii(quantity));

    return parsed != null && parsed > 0;
  }

  /// What one line is worth, for the running estimate only.
  double get estimate {
    final q = double.tryParse(_ascii(quantity)) ?? 0;
    final p = double.tryParse(unitPrice) ?? 0;

    return q * p;
  }
}

/// The sheet, as a closed set of shapes.
///
/// One class rather than a union, and deliberately: unlike a screen that is either loading or
/// loaded, this one is *always* showing an editable form. `isSaving` and `failure` are things
/// that happen to that form, not replacements for it — a union here would mean rebuilding the
/// whole editor to say "saving", throwing away every controller and the keyboard with them.
@freezed
abstract class OrderInvoiceState with _$OrderInvoiceState {
  const factory OrderInvoiceState({
    required int orderId,
    required List<InvoiceLine> lines,
    required String discount,
    required String designFee,
    required String deliveryPrice,

    /// Where the order is going, as it stands on screen.
    ///
    /// Seeded from the order's own snapshot and replaced wholesale when a city is picked — the
    /// region goes with it, because a region belongs to one city and keeping the old one would
    /// send the server a neighbourhood from somewhere else.
    required int cityId,
    required String cityName,
    int? regionId,
    String? regionName,

    /// Whether the lines may be touched at all. False from «جاهزة» onwards, where this screen
    /// is open for the address alone.
    @Default(false) bool linesAreEditable,

    /// The number the courier rings. Null on an order taken without one.
    ///
    /// Beside the address rather than in a section of its own, because it is governed by the
    /// same rule and for the same reason — see [destinationIsEditable].
    String? recipientPhone,

    /// Whether the address **and the recipient's phone** may be touched. Open in every status
    /// but «جاري التوصيل»: past that point the courier is carrying both, and our copy changing
    /// while his does not is worse than a wrong number we can telephone him about.
    @Default(false) bool destinationIsEditable,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
    @Default(false) bool isDirty,
    Failure? failure,
  }) = _OrderInvoiceState;

  const OrderInvoiceState._();

  /// An order must keep at least one line, and every quantity has to be a real number — the
  /// same two rules the server enforces, checked here so the refusal is instant.
  ///
  /// Only asked of the lines when they are editable: on an order past «جاهزة» this screen never
  /// sends them, so a quantity it is merely displaying cannot be a reason to refuse a save.
  bool get isValid =>
      !linesAreEditable ||
      (lines.isNotEmpty && lines.every((line) => line.hasValidQuantity));

  /// Where it goes, as one line: «طرابلس — سوق الجمعة».
  String get destination => regionName == null ? cityName : '$cityName — $regionName';

  /// The server's complaint about the phone, to be painted under that box rather than shouted
  /// in a snackbar — «لا يمكن تغيير هاتف الاستلام وحالة الطلبية ‹جاري التوصيل›» belongs beside
  /// the number it is about.
  String? get recipientPhoneError => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?['recipient_phone']?.firstOrNull,
    _ => null,
  };

  /// What the total will *probably* be. The server's arithmetic is the invoice; this exists so
  /// the number moves while somebody is typing.
  String get estimatedTotal {
    final items = lines.fold<double>(0, (sum, line) => sum + line.estimate);
    final extras = (double.tryParse(designFee) ?? 0) + (double.tryParse(deliveryPrice) ?? 0);
    final off = double.tryParse(_ascii(discount)) ?? 0;

    return (items + extras - off).clamp(0, double.infinity).toStringAsFixed(2);
  }
}

/// Arabic-Indic and Persian digits to ASCII.
///
/// The keyboard a Libyan clerk uses produces `٣٠٠`, and `double.tryParse` answers null for it —
/// which would read on screen as "that quantity is invalid" for a number they typed correctly.
String _ascii(String value) => value.split('').map((c) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final a = arabic.indexOf(c);
  if (a != -1) return '$a';
  final p = persian.indexOf(c);
  if (p != -1) return '$p';

  // A comma is a decimal separator on an Arabic keyboard.
  return c == ',' ? '.' : c;
}).join();
