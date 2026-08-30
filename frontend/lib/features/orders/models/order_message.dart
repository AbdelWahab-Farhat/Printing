import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';

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
/// heading with a blank line above it lets a reader jump: *what I ordered*, *what I owe*, *where
/// I collect it*. The headings carry an emoji rather than bold marks, deliberately: a variant
/// label like `35*40` puts a stray asterisk in the message, and WhatsApp's own bold syntax is
/// asterisks.
///
/// **Nothing here is computed.** Every amount is the string the server sent — «المتبقي» is not
/// `grandTotal - paidAmount` worked out on the phone, for the same reason the screen does not do
/// it either: that would be a second answer to one question, and the phone's is made of doubles.
///
/// **A section with nothing to say is absent**, not empty. An order with no design fee, no
/// discount and no notes should read as an order without those things, not as an order with
/// three blank headings under it.
///
/// **What staff need and the customer does not is not here at all.** The status and the
/// customer's own name are on the screen for the clerk, and each of them was a line the customer
/// had to read past to reach the number they were asking about.
class OrderMessage {
  const OrderMessage._();

  /// Written after every amount, the way the message it was modelled on writes it — «875 د».
  /// The app's own screens leave money bare, because the reader there already knows; the person
  /// receiving this does not necessarily.
  static const String currency = 'د';

  static const String itemsHeading = '🛍️ المطلوب';
  static const String moneyHeading = '💰 الحساب';
  static const String notesHeading = '📝 ملاحظات';

  /// One label for both office pickup and delivery, because it answers the same question either
  /// way: the place this order reaches its owner.
  static const String placeLabel = 'مكان الإستلام';

  /// The whole message, ready to be pasted into a chat.
  static String of(Order order) {
    final sections = <String>[
      _header(order),
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

  /// Which invoice this is, when it was taken, whose it is, and the one number it will be
  /// received on.
  ///
  /// **No name.** The customer knows who they are, and the message arrives on their own phone;
  /// the name was there for the clerk, who reads it on the screen instead.
  ///
  /// **One number, never two.** The recipient's when the order has one, the customer's when it
  /// does not — printing both makes the reader work out which of them the order is coming to.
  static String _header(Order order) => _section('🖨️ رقم فاتورة: #${order.code}', [
    if (_dayOf(order) case final day?) 'التاريخ: $day',
    if (order.customer case final customer?) 'كود الزبون: ${customer.code}',
    if (_receivingPhone(order) case final phone?) 'رقم المستلم: $phone',
  ], alwaysShown: true);

  static String? _receivingPhone(Order order) => order.recipientPhone ?? order.customer?.phone;

  /// The day the order was taken, at the top where the reader looks for it.
  ///
  /// Not [Order.placedAgo]: «منذ ٣ أيام» is true when it is copied and wrong by the time the
  /// customer scrolls back to it, and a message is read long after it is sent. The same words
  /// the app draws everywhere else, so «14 أغسطس 2026» never asks which half of `2026-08-14` is
  /// the month.
  static String? _dayOf(Order order) => (order.placedAt ?? order.createdAt)?.dayLabel;

  /// The bags, each numbered, then what there is to check about them under it.
  ///
  /// **Numbered rather than bulleted**, because an order of four sizes is discussed on the phone
  /// by position — «التاني، اللي 30*40» — and a row of identical dots gives nobody anything to
  /// say. The number is also what the reader counts against «طلبت تلاتة».
  ///
  /// Under the name, one fact per line: the count, then what that count came to. A customer
  /// checking a message checks those two things separately, and a single run-on line asks them
  /// to find each in the middle of the other.
  static String _items(Order order) {
    final items = order.items ?? const <OrderItem>[];
    if (items.isEmpty) return '';

    final lines = <String>[];

    for (final (index, item) in items.indexed) {
      lines
        ..add('${index + 1}. ${item.productName} — ${item.variantLabel}:')
        // Padding zeros are the database's, not the shop's: an order of «100.000 قطعة» is an
        // order of a hundred bags.
        ..add('- الكمية: ${groupedDecimal(item.quantity)} ${item.pricingUnitLabel}')
        ..add('- القيمة: ${_amount(item.lineTotal)}');

      // Said on the line it is missing from, because that is the only place the number means
      // anything: «ناقص ٤٠» of *which* size.
      if (item.shortageQuantity case final missing?) {
        lines.add('- ناقص: ${groupedDecimal(missing)} ${item.pricingUnitLabel}');
      }
    }

    return _section(itemsHeading, lines);
  }

  /// Every charge that made the bill, then what is left of it.
  ///
  /// **«التوصيل» is a line here**, unlike in the first version of this message: on an order that
  /// was charged for delivery, the fee is a figure the customer is being asked to pay, and
  /// leaving it out left a gap between the products and what was owed that nothing explained.
  ///
  /// A charge of nothing is still absent, delivery included. The screen prints the `0.00` an
  /// office pickup costs because a member of staff checking a total wants to see that it is
  /// nothing rather than infer it; on this copy a zero line is a question, not an answer.
  ///
  /// **«الإجمالي» is not here, by the owner's instruction.** The charges add up to it and
  /// «المدفوع» and «المتبقي» are read off it, so it is a line the reader can do without.
  static String _money(Order order) => _section(moneyHeading, [
    'المنتجات: ${_amount(order.itemsTotal)}',
    if (order.hasDesignFee) 'التصميم: ${_amount(order.designFee)}',
    if (order.hasDeliveryPrice) 'التوصيل: ${_amount(order.deliveryPrice)}',
    if (order.hasDiscount) 'الخصم: - ${_amount(order.discount)}',
    'المدفوع: ${_amount(order.paidAmount)}',
    'المتبقي: ${_amount(order.remainingAmount)}',
  ]);

  /// Where the order reaches its owner, with no heading of its own.
  ///
  /// One line is all most orders need here, and a line under an emoji heading of its own was a
  /// section built for a single fact. «هاتف المستلم» is not repeated — it is in the header, the
  /// only number on the message.
  static String _destination(Order order) => _section('$placeLabel: ${order.destination}', [
    if (order.customerShopName case final shop?) 'المحل: $shop',
    if (order.addressDetails case final address?) 'العنوان: $address',
    if (order.recipientName case final name?) 'المستلم: $name',
    if (order.shippingCompany case final company?) 'شركة الشحن: $company',
    if (order.trackingNumber case final tracking?) 'رقم التتبع: $tracking',
  ], alwaysShown: true);

  /// A section of their own, though the screen keeps them under the address — and **only while
  /// the order is «جديدة»**, by the owner's instruction.
  ///
  /// The note on an order is written when it is taken («دفع عربون بقيمة 30 د ليبيانا», «شعار
  /// فقط») and it is asking the customer to confirm something before the work starts. On an
  /// order already printed, already out for delivery, already settled, that same sentence is a
  /// stale instruction the customer can no longer act on.
  static String _notes(Order order) {
    if (order.status != OrderStatus.taken) return '';

    final notes = order.notes?.trim();

    return notes == null || notes.isEmpty ? '' : _section(notesHeading, [notes]);
  }

  /// A heading and its lines. Empty when there are no lines — unless the heading is itself the
  /// fact, the way «مكان الإستلام: درنة» and the invoice number are.
  static String _section(String heading, List<String> lines, {bool alwaysShown = false}) =>
      lines.isEmpty && !alwaysShown ? '' : [heading, ...lines].join('\n');

  /// Grouped, like every figure the app draws: a customer reading «2,975 د» on their phone is
  /// reading the same number the clerk read on theirs.
  static String _amount(String value) => '${value.grouped} $currency';
}
