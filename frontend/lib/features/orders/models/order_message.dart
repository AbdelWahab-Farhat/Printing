import 'package:printing/features/orders/models/order.dart';

/// The order written out as a message, for a reader who does not have the app.
///
/// **This is the only text in the project written for the customer rather than for staff.** It
/// is what «نسخ الفاتورة» puts on the clipboard and what «مشاركة الفاتورة» hands to the phone's
/// own share sheet — one text, so the two doors can never disagree about what an order says.
///
/// ## Why it is sections
///
/// The message it replaces was a single column of twelve lines, and the number somebody rings
/// about — «المتبقي» — sat in the middle of it with nothing to separate it from the address. A
/// heading with a blank line above it lets a reader jump: *my number*, *what I ordered*, *what I
/// owe*, *where I collect it*. The headings carry an emoji rather than bold marks, deliberately:
/// a variant label like `35*40` puts a stray asterisk in the message, and WhatsApp's own bold
/// syntax is asterisks.
///
/// **Nothing here is computed.** Every amount is the string the server sent — «المتبقي» is not
/// `grandTotal - paidAmount` worked out on the phone, for the same reason the screen does not do
/// it either: that would be a second answer to one question, and the phone's is made of doubles.
///
/// **A section with nothing to say is absent**, not empty. An order with no design fee, no
/// discount and no notes should read as an order without those things, not as an order with
/// three blank headings under it.
class OrderMessage {
  const OrderMessage._();

  /// Written after every amount, the way the message it was modelled on writes it — «875 د».
  /// The app's own screens leave money bare, because the reader there already knows; the person
  /// receiving this does not necessarily.
  static const String currency = 'د';

  static const String orderHeading = '📄 الطلبية';
  static const String customerHeading = '👤 الزبون';
  static const String itemsHeading = '🛍️ المطلوب';
  static const String moneyHeading = '💰 الحساب';

  /// Two headings for one section, because they are two different instructions: one says come
  /// and get it, the other says it is coming to you.
  static const String pickupHeading = '📦 الاستلام';
  static const String deliveryHeading = '🚚 التوصيل';

  static const String notesHeading = '📝 ملاحظات';

  /// The whole message, ready to be pasted into a chat.
  static String of(Order order) {
    final sections = <String>[
      '🖨️ فاتورة طلبية #${order.code}',
      _order(order),
      _customer(order),
      _items(order),
      _money(order),
      _destination(order),
      _notes(order),
    ];

    return [
      for (final section in sections)
        if (section.isNotEmpty) section,
    ].join('\n\n');
  }

  /// What an email app writes on the subject line when the share sheet lands there.
  ///
  /// Chat apps ignore it; the ones that do not would otherwise send a mail with an empty
  /// subject, which reads as spam.
  static String subjectOf(Order order) => 'فاتورة طلبية #${order.code}';

  static String _order(Order order) => _section(orderHeading, [
    // The server's own Arabic for the status — a state added after this release still reads
    // correctly here, the same way it does on the screen.
    'الحالة: ${order.statusLabel}',
    if (_dayOf(order) case final day?) 'التاريخ: $day',
  ]);

  static String _customer(Order order) {
    final customer = order.customer;
    if (customer == null) return '';

    return _section(customerHeading, [
      'كود الزبون: ${customer.code}',
      'الإسم: ${customer.name}',
      'الرقم: ${customer.phone}',
    ]);
  }

  /// The bags, each numbered, on two lines: what it is, then how many at what price.
  ///
  /// **Numbered rather than bulleted**, because an order of four sizes is discussed on the phone
  /// by position — «التاني، اللي 30*40» — and a row of identical dots gives nobody anything to
  /// say. The number is also what the reader counts against «طلبت تلاتة».
  ///
  /// Split across two lines rather than run together, because the first is the line the customer
  /// checks against what they asked for and the second is the one they check against the total.
  static String _items(Order order) {
    final items = order.items ?? const <OrderItem>[];
    if (items.isEmpty) return '';

    final lines = <String>[];

    for (final (index, item) in items.indexed) {
      lines
        ..add('${index + 1}. ${item.productName} — ${item.variantLabel}')
        ..add(
          '   ${item.quantity} ${item.pricingUnitLabel} × ${item.unitPrice} = ${_amount(item.lineTotal)}',
        );

      // Said on the line it is missing from, because that is the only place the number means
      // anything: «ناقص ٤٠» of *which* size.
      if (item.shortageQuantity case final missing?) {
        lines.add('   ناقص: $missing ${item.pricingUnitLabel}');
      }
    }

    return _section(itemsHeading, lines);
  }

  /// The screen's «الحساب» card, minus one line.
  ///
  /// **«التوصيل» is not on the message, at the owner's instruction** — the screen still shows it,
  /// including the `0.00` an office pickup costs, because a member of staff checking a total
  /// wants to see that it is nothing rather than infer it. The customer's copy leaves it out.
  ///
  /// The consequence, stated so nobody has to rediscover it: on an order that *was* charged for
  /// delivery, «المنتجات» plus the fees no longer reach «الإجمالي», and the gap is silent.
  static String _money(Order order) => _section(moneyHeading, [
    'المنتجات: ${_amount(order.itemsTotal)}',
    if (order.hasDesignFee) 'التصميم: ${_amount(order.designFee)}',
    if (order.hasDiscount) 'الخصم: - ${_amount(order.discount)}',
    'الإجمالي: ${_amount(order.grandTotal)}',
    'المدفوع: ${_amount(order.paidAmount)}',
    'المتبقي: ${_amount(order.remainingAmount)}',
  ]);

  static String _destination(Order order) => _section(
    order.isOfficePickup ? pickupHeading : deliveryHeading,
    [
      '${order.fulfilmentTypeLabel}: ${order.destination}',
      if (order.customerShopName case final shop?) 'المحل: $shop',
      if (order.addressDetails case final address?) 'العنوان: $address',
      if (order.recipientName case final name?) 'المستلم: $name',
      if (order.recipientPhone case final phone?) 'هاتف المستلم: $phone',
      if (order.shippingCompany case final company?) 'شركة الشحن: $company',
      if (order.trackingNumber case final tracking?) 'رقم التتبع: $tracking',
    ],
  );

  /// A section of their own, though the screen keeps them under the address.
  ///
  /// «شعار فقط» is an instruction about the work, not about where it goes, and on the message it
  /// is often the last thing the customer is asked to confirm.
  static String _notes(Order order) {
    final notes = order.notes?.trim();

    return notes == null || notes.isEmpty ? '' : _section(notesHeading, [notes]);
  }

  static String _section(String heading, List<String> lines) =>
      lines.isEmpty ? '' : [heading, ...lines].join('\n');

  static String _amount(String value) => '$value $currency';

  /// The day the order was taken, `Y-m-d`.
  ///
  /// Not [Order.placedAgo]: «منذ ٣ أيام» is true when it is copied and wrong by the time the
  /// customer scrolls back to it, and a message is read long after it is sent.
  static String? _dayOf(Order order) {
    final at = (order.placedAt ?? order.createdAt)?.toLocal();
    if (at == null) return null;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${at.year}-${two(at.month)}-${two(at.day)}';
  }
}
