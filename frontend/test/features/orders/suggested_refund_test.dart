import 'package:dayaa/features/orders/presentation/widgets/record_payment_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// What «ردّ مبلغ للعميل» opens on — the overpaid part on an overpaid order, everything paid
/// otherwise.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('an overpaid order opens on what was paid beyond it', () {
    // Act — 330 paid on an order now worth 300.
    final amount = suggestedRefund(remainingAmount: '-30.00', paidAmount: '330.00');

    // Assert
    expect(amount, '30.00');
  });

  test('an order that is not overpaid opens on everything paid, as before', () {
    // Act
    final owing = suggestedRefund(remainingAmount: '120.00', paidAmount: '200.00');
    final settled = suggestedRefund(remainingAmount: '0.00', paidAmount: '200.00');

    // Assert
    expect(owing, '200.00');
    expect(settled, '200.00');
  });

  test('the overpaid part never opens above what was actually paid', () {
    // Arrange — 60 paid and 40 written off on a 100 order, then cut to 30: 70 over, of which
    // only 60 is cash anybody can hand back.
    final amount = suggestedRefund(remainingAmount: '-70.00', paidAmount: '60.00');

    // Assert
    expect(amount, '60.00');
  });

  test('nothing paid, nothing suggested', () {
    // Act
    final amount = suggestedRefund(remainingAmount: '-20.00', paidAmount: '0.00');

    // Assert
    expect(amount, isNull);
  });
}
