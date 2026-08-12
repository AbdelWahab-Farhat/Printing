import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_message.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';

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
    quantity: '400',
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
    String? notes,
    String? recipientPhone,
    String? trackingNumber,
  }) => Order(
    id: 55,
    code: '55',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
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

  test('it opens with the order number, so a forwarded message says what it is about', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message.split('\n').first, contains('#55'));
  });

  test('every section is there, in the order somebody reads them', () {
    // Arrange
    final order = orderWith(notes: 'شعار فقط', recipientPhone: '0911111111');

    // Act
    final message = OrderMessage.of(order);
    final headings = [
      OrderMessage.orderHeading,
      OrderMessage.customerHeading,
      OrderMessage.itemsHeading,
      OrderMessage.moneyHeading,
      OrderMessage.pickupHeading,
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
    expect(message, contains('\n\n${OrderMessage.customerHeading}'));
    expect(message, contains('\n\n${OrderMessage.moneyHeading}'));
  });

  test('the customer reads their own code, name and number', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('كود الزبون: C10'));
    expect(message, contains('الإسم: عبدالوهاب'));
    expect(message, contains('الرقم: 0944909850'));
  });

  test('a line names the bags, then counts them at the price they were sold at', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('أكياس الشحن — 35*40'));
    expect(message, contains('400 قطعة × 1.050 = 420.00 د'));
  });

  test('the lines are numbered, so an order of four sizes can be talked about', () {
    // Arrange
    final order = orderWith(
      items: [
        item,
        item.copyWith(id: 2, variantLabel: '30*40', quantity: '200', lineTotal: '210.00'),
      ],
    );

    // Act
    final message = OrderMessage.of(order);

    // Assert — the number belongs to the line that names the bags, not to its price.
    expect(message, contains('1. أكياس الشحن — 35*40'));
    expect(message, contains('2. أكياس الشحن — 30*40'));
  });

  test('what is missing is said on the line it is missing from', () {
    // Arrange
    final order = orderWith(items: [item.copyWith(shortageQuantity: '40')]);

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('ناقص: 40 قطعة'));
  });

  test('the money is the three numbers the customer asks about', () {
    // Arrange
    final order = orderWith(paidAmount: '100.00', remainingAmount: '320.00');

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, contains('الإجمالي: 420.00 د'));
    expect(message, contains('المدفوع: 100.00 د'));
    expect(message, contains('المتبقي: 320.00 د'));
  });

  test('the delivery price is never on the message, charged or not', () {
    // Arrange — the screen shows it either way; this is the owner's own line about the copy the
    // customer gets. See ORDER-INVOICE-MESSAGE.md §١٠.
    final free = orderWith();
    final charged = orderWith(deliveryPrice: '50.00');

    // Act
    final atTheCounter = OrderMessage.of(free);
    final toTheDoor = OrderMessage.of(charged);

    // Assert
    expect(atTheCounter, isNot(contains('التوصيل')));
    expect(toTheDoor, isNot(contains('التوصيل')));
    expect(toTheDoor, isNot(contains('50.00')));
  });

  test('a fee of nothing is not a fact about the order, so it is left out', () {
    // Arrange
    final withNothing = orderWith();
    final withBoth = orderWith(designFee: '25.00', discount: '10.00');

    // Act
    final quiet = OrderMessage.of(withNothing);
    final full = OrderMessage.of(withBoth);

    // Assert
    expect(quiet, isNot(contains('التصميم')));
    expect(quiet, isNot(contains('الخصم')));
    expect(full, contains('التصميم: 25.00 د'));
    expect(full, contains('الخصم: - 10.00 د'));
  });

  test('an order being delivered is headed for delivery, not for the counter', () {
    // Arrange
    final pickup = orderWith();
    final delivery = orderWith(isOfficePickup: false, trackingNumber: 'LY-9');

    // Act
    final atTheCounter = OrderMessage.of(pickup);
    final onTheRoad = OrderMessage.of(delivery);

    // Assert
    expect(atTheCounter, contains(OrderMessage.pickupHeading));
    expect(onTheRoad, contains(OrderMessage.deliveryHeading));
    expect(onTheRoad, contains('رقم التتبع: LY-9'));
  });

  test('a section with nothing in it is absent rather than empty', () {
    // Arrange — no notes, and an order fetched without its customer or its lines.
    final order = orderWith(items: null, customer_: null);

    // Act
    final message = OrderMessage.of(order);

    // Assert
    expect(message, isNot(contains(OrderMessage.notesHeading)));
    expect(message, isNot(contains(OrderMessage.customerHeading)));
    expect(message, isNot(contains(OrderMessage.itemsHeading)));
    expect(message.trim(), message);
  });

  test('the date is the day the order was taken, not the day it is read', () {
    // Arrange
    final order = orderWith();

    // Act
    final message = OrderMessage.of(order);

    // Assert — «منذ ٣ أيام» would be a different sentence tomorrow.
    expect(message, contains('التاريخ: 2026-08-12'));
    expect(message, contains('الحالة: جديدة'));
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
