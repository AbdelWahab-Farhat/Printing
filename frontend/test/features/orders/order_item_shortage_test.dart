import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// What a line says when part of it is missing.
///
/// The invoice charges for what is left — `billable = quantity − shortage` — so the line has
/// three numbers to show and not two: what was ordered, what is missing, and what is being paid
/// for. The subtraction is the server's; these getters only decide how it reads.
///
/// Arrange - Act - Assert throughout.
void main() {
  OrderItem line({String? shortage, String? billable}) => OrderItem(
    id: 11,
    productId: 1,
    productVariantId: 2,
    productName: 'كيس شحن',
    variantLabel: '25*35',
    pricingUnitLabel: 'قطعة',
    quantity: '300.000',
    shortageQuantity: shortage,
    billableQuantity: billable,
    unitPrice: '1.550',
    lineTotal: shortage == null ? '465.00' : '310.00',
  );

  test('a whole line is priced on everything that was ordered', () {
    // Arrange
    final item = line();

    // Act & Assert — nothing missing, so there is no second number to read and the line says
    // what it always said.
    expect(item.hasShortage, isFalse);
    expect(item.pricedQuantity, '300.000');
  });

  test('a short line is priced on what is left of it', () {
    // Arrange
    final item = line(shortage: '100.000', billable: '200.000');

    // Act & Assert
    expect(item.hasShortage, isTrue);
    expect(item.pricedQuantity, '200.000');
  });

  test('a shortage of zero is not a shortage', () {
    // Arrange — the server clears a shortage to null, but a zero typed straight into the sheet
    // reaches here before the round trip does.
    final item = line(shortage: '0.000', billable: '300.000');

    // Act & Assert — a red «ناقص ٠» is a warning about nothing, and warnings about nothing
    // teach people to stop reading them.
    expect(item.hasShortage, isFalse);
  });

  test('an older server that does not send the billable quantity is not misread', () {
    // Arrange — the field is new; a build talking to a server without it must not decide the
    // line is free.
    final item = line(shortage: '100.000');

    // Act & Assert — falls back to what was ordered, which is what that server was charging.
    expect(item.pricedQuantity, '300.000');
  });

  test('the whole line going missing still reads as a line', () {
    // Arrange
    final item = line(shortage: '300.000', billable: '0.000');

    // Act & Assert — nothing arrived, nothing is charged, and the order still says what was
    // asked for.
    expect(item.hasShortage, isTrue);
    expect(item.pricedQuantity, '0.000');
  });

  /// **«تعديل النواقص» belongs to one status.**
  ///
  /// The sheet exists for the job that is parked because the stock is not there. The two moves
  /// either side of that already ask the same question where it belongs — entering «نواقص» asks
  /// what is short, leaving it asks what arrived — so an arm on the dial anywhere else would be
  /// a third door to a room with two.
  group('when the shortages sheet is offered', () {
    Order order(OrderStatus status) => Order(
      id: 7,
      code: '7',
      status: status,
      statusLabel: status.name,
      isFinal: false,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsAreEditable: true,
      designsAreEditable: false,
      itemsTotal: '420.00',
      designFee: '0.00',
      deliveryPrice: '0.00',
      discount: '0.00',
      grandTotal: '420.00',
    );

    test('in «نواقص», and there alone', () {
      // Act & Assert
      expect(order(OrderStatus.shortage).shortagesAreEditable, isTrue);
    });

    test('not while the lines are merely still open', () {
      // Act & Assert — `items_are_editable` is true for all three of these, and it used to be
      // what the arm was drawn from: the sheet turned up on «جديدة» and «قيد الطباعة», where
      // there is no shortage to argue about.
      for (final status in [OrderStatus.taken, OrderStatus.designing, OrderStatus.printing]) {
        expect(order(status).shortagesAreEditable, isFalse, reason: status.name);
      }
    });

    test('not once the bags exist or the order is over', () {
      // Act & Assert
      for (final status in [OrderStatus.ready, OrderStatus.delivered, OrderStatus.cancelled]) {
        expect(order(status).shortagesAreEditable, isFalse, reason: status.name);
      }
    });
  });
}
