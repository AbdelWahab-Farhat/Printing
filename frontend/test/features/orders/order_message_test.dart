import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_message.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// The order, written out as the message a customer actually receives.
///
/// This is the one place in the app whose output is read by somebody who never sees the app —
/// so it is tested for what it *says*, not for how it is built. See ORDER-INVOICE-MESSAGE.md.
///
/// Arrange - Act - Assert throughout.
void main() {
  const customer = Customer(
    id: 10,
    code: 'C10',
    name: 'عبدالوهاب',
    phone: '0944909850',
    isActive: true,
  );

  const item = OrderItem(
    id: 1,
    productId: 3,
    productVariantId: 9,
    productName: 'أكياس الشحن',
    variantLabel: '35*40',
    pricingUnitLabel: 'قطعة',
    quantity: '400.000',
    unitPrice: '1.050',
    lineTotal: '420.00',
  );

  Order orderWith({
    List<OrderItem>? items = const [item],
    Customer? customer_ = customer,
    String designFee = '0.00',
    String deliveryPrice = '0.00',
    String discount = '0.00',
    String paidAmount = '0.00',
    String remainingAmount = '420.00',
    bool isOfficePickup = true,
    OrderStatus status = OrderStatus.taken,
    String? notes,
    String? recipientPhone,
    String? trackingNumber,
  }) => Order(
    id: 55,
    code: '55',
    status: status,
    statusLabel: status.label,
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: isOfficePickup ? 'استلام مكتب' : 'توصيل',
    isOfficePickup: isOfficePickup,
    designSourceLabel: 'من الزبون',
    itemsTotal: '420.00',
    designFee: designFee,
    deliveryPrice: deliveryPrice,
    discount: discount,
    grandTotal: '420.00',
    paidAmount: paidAmount,
    remainingAmount: remainingAmount,
    paymentStatus: PaymentStatus.unpaid,
    paymentStatusLabel: 'غير مدفوعة',
    customer: customer_,
    items: items,
    notes: notes,
    recipientPhone: recipientPhone,
    trackingNumber: trackingNumber,
    placedAt: DateTime(2026, 8, 12),
  );

  test('it opens with the invoice number, the day, the code and one number to reach', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert — five lines, no heading between them: this is what a forwarded message is read by.
    expect(message.split('\n\n').first, '''
🖨️ رقم فاتورة: #55
التاريخ: 12 أغسطس 2026
كود الزبون: C10
رقم المستلم: 0944909850
مكان الإستلام: طرابلس''');
  });

  test('the number is the recipient\'s when the order has one, and never both', () {
    // Arrange
    final order = orderWith(recipientPhone: '0911111111');

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('رقم المستلم: 0911111111'));
    expect(message, isNot(contains('0944909850')));
  });

  test('the customer is not told their own name', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, isNot(contains('عبدالوهاب')));
    expect(message, isNot(contains('الإسم')));
  });

  test('the status is the office\'s business, not the customer\'s', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, isNot(contains('الحالة')));
    expect(message, isNot(contains('جديدة')));
  });

  test('every section is there, in the order somebody reads them', () {
    // Arrange
    final order = orderWith(notes: 'شعار فقط');

    // Act
    final message = OrderMessage.of(order);
    final headings = [
      OrderMessage.placeLabel,
      OrderMessage.itemsHeading,
      OrderMessage.moneyHeading,
      OrderMessage.notesHeading,
    ].map(message.indexOf).toList();

    // Assert — every one found, and each after the one before it.
    expect(headings, everyElement(isNonNegative));
    expect(headings, orderedEquals(<int>[...headings]..sort()));
  });

  test('the sections are separated by a blank line, which is what makes them sections', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert — the heading of a section never sits on the line under another section's last row.
    expect(message, contains('\n\n${OrderMessage.itemsHeading}'));
    expect(message, contains('\n\n${OrderMessage.moneyHeading}'));
  });

  test('a line names the bags, then counts them and says what they came to', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert — «400.000» is the database's padding, not a quantity anybody ordered.
    expect(message, contains('1. أكياس الشحن — 35*40:'));
    expect(message, contains('- الكمية: 400 قطعة'));
    expect(message, contains('- القيمة: 420 د'));
  });

  test('the lines are numbered, so an order of four sizes can be talked about', () {
    // Arrange
    final order = orderWith(
      items: [
        item,
        item.copyWith(id: 2, variantLabel: '30*40', quantity: '200.000', lineTotal: '210.00'),
      ],
    );

    // Act
    final message = OrderMessage.of(order);

    // Assert — the number belongs to the line that names the bags, not to its count.
    expect(message, contains('1. أكياس الشحن — 35*40:'));
    expect(message, contains('2. أكياس الشحن — 30*40:'));
  });

  test('what is missing is said on the line it is missing from', () {
    // Arrange
    final order = orderWith(items: [item.copyWith(shortageQuantity: '40.000')]);

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('- ناقص: 40 قطعة'));
  });

  test('the money is every charge that made the bill, then what is left of it', () {
    // Arrange
    final order = orderWith(
      isOfficePickup: false,
      designFee: '20.00',
      deliveryPrice: '50.00',
      discount: '10.00',
      paidAmount: '30.00',
      remainingAmount: '450.00',
    );

    // Act
    final positions = <String>[
      'المنتجات: 420 د',
      'التصميم: 20 د',
      'التوصيل: 50 د',
      'الخصم: - 10 د',
      'المدفوع: 30 د',
      'المتبقي: 450 د',
    ].map(OrderMessage.of(order).indexOf).toList();

    // Assert — every one found, each below the one before it.
    expect(positions, everyElement(isNonNegative));
    expect(positions, orderedEquals(<int>[...positions]..sort()));
  });

  test('an amount is written the way it is said, without the database\'s padding', () {
    // Arrange — a bill of whole dinars, and one with a fraction somebody actually pays.
    final whole = orderWith(deliveryPrice: '40.00', paidAmount: '30.00', remainingAmount: '430.00');
    final fractional = orderWith(
      items: [item.copyWith(quantity: '100.000', lineTotal: '12.250')],
      deliveryPrice: '1.500',
      remainingAmount: '13.750',
    );

    // Act
    final round = OrderMessage.of(whole);
    final broken = OrderMessage.of(fractional);

    // Assert — a whole number loses the point entirely; a real fraction keeps only its digits.
    expect(round, contains('التوصيل: 40 د'));
    expect(round, contains('المدفوع: 30 د'));
    expect(round, isNot(contains('.00')));
    expect(broken, contains('- الكمية: 100 قطعة'));
    expect(broken, contains('- القيمة: 12.25 د'));
    expect(broken, contains('التوصيل: 1.5 د'));
    expect(broken, contains('المتبقي: 13.75 د'));
  });

  test('«الإجمالي» is not a line, by the owner\'s instruction', () {
    // Arrange
    final order = orderWith(deliveryPrice: '50.00');

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, isNot(contains('الإجمالي')));
  });

  test('a charge of nothing is not a fact about the order, so it is left out', () {
    // Arrange
    final withNothing = orderWith();
    final withEverything = orderWith(designFee: '25.00', deliveryPrice: '50.00', discount: '10.00');

    // Act
    final quiet = OrderMessage.of(withNothing);
    final full = OrderMessage.of(withEverything);

    // Assert
    expect(quiet, isNot(contains('التصميم')));
    expect(quiet, isNot(contains('التوصيل')));
    expect(quiet, isNot(contains('الخصم')));
    expect(full, contains('التصميم: 25 د'));
    expect(full, contains('التوصيل: 50 د'));
    expect(full, contains('الخصم: - 10 د'));
  });

  test('where it is received is one line, whether it is fetched or delivered', () {
    // Arrange
    final pickup = orderWith();
    final delivery = orderWith(isOfficePickup: false, trackingNumber: 'LY-9');

    // Act
    final atTheCounter = OrderMessage.of(pickup);
    final onTheRoad = OrderMessage.of(delivery);

    // Assert
    expect(atTheCounter, contains('مكان الإستلام: طرابلس'));
    expect(onTheRoad, contains('مكان الإستلام: طرابلس'));
    expect(onTheRoad, contains('رقم التتبع: LY-9'));
  });

  test('the note is asked about while the order is new, and not after', () {
    // Arrange — the same note on an order just taken and on one already on the road.
    const note = 'دفع عربون بقيمة 30 د ليبيانا';
    final justTaken = orderWith(notes: note);
    final onTheRoad = orderWith(notes: note, status: OrderStatus.outForDelivery);

    // Act
    final fresh = OrderMessage.of(justTaken);
    final later = OrderMessage.of(onTheRoad);

    // Assert
    expect(fresh, contains(note));
    expect(later, isNot(contains(note)));
    expect(later, isNot(contains(OrderMessage.notesHeading)));
  });

  test('a section with nothing in it is absent rather than empty', () {
    // Arrange — no notes, and an order fetched without its customer or its lines.
    final order = orderWith(items: null, customer_: null);

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, isNot(contains(OrderMessage.notesHeading)));
    expect(message, isNot(contains(OrderMessage.itemsHeading)));
    expect(message, isNot(contains('كود الزبون')));
    expect(message, isNot(contains('رقم المستلم')));
    expect(message.trim(), message);
  });

  test('the subject an email app puts on it names the order', () {
    // Arrange
    final order = orderWith();

    // Act
    final subject = OrderMessage.subjectOf(order);

    // Assert
    expect(subject, contains('55'));
  });
}
