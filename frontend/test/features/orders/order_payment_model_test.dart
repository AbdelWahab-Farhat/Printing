import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a ledger entry reads off the wire — here, the receipt flags the server decides.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The least JSON an entry arrives as, with room to disagree per test.
  Map<String, dynamic> entry([Map<String, dynamic> overrides = const {}]) => {
    'id': 11,
    'order_id': 7,
    'type': 'payment',
    'type_label': 'دفعة',
    'amount': '150.00',
    ...overrides,
  };

  test('a photographed receipt announces itself, so the app draws it', () {
    // Arrange
    final json = entry({
      'has_receipt': true,
      'receipt_is_image': true,
      'receipt_url': 'https://api.example.ly/storage/payment-receipts/7/a.jpg',
      'receipt_filename': 'waseel.jpg',
    });

    // Act
    final payment = OrderPayment.fromJson(json);

    // Assert
    expect(payment.hasReceipt, isTrue);
    expect(payment.receiptIsImage, isTrue);
  });

  test('a PDF receipt stays a document the phone opens', () {
    // Arrange
    final json = entry({
      'has_receipt': true,
      'receipt_is_image': false,
      'receipt_filename': 'waseel.pdf',
    });

    // Act
    final payment = OrderPayment.fromJson(json);

    // Assert
    expect(payment.receiptIsImage, isFalse);
  });

  test('a server from before the flag existed reads as PDFs, which is all it could hold', () {
    // Arrange — no `receipt_is_image` key at all.
    final json = entry({'has_receipt': true, 'receipt_filename': 'waseel.pdf'});

    // Act
    final payment = OrderPayment.fromJson(json);

    // Assert
    expect(payment.receiptIsImage, isFalse);
  });
}
