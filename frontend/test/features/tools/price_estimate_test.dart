import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/tools/models/price_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

/// The total and the message the price calculator hands the customer.
///
/// Arrange - Act - Assert throughout.
void main() {
  PriceQuote quote({required String quantity, required String unitPrice, required String total}) =>
      PriceQuote(
        quantity: quantity,
        unit: 'piece',
        unitLabel: 'قطعة',
        unitPrice: unitPrice,
        total: total,
        appliedTierMinQuantity: '300.000',
      );

  final shippingSmall = EstimateEntry(
    productName: 'أكياس الشحن',
    sizeLabel: '25*35',
    quantity: '500',
    unitLabel: 'قطعة',
    quote: quote(quantity: '500.000', unitPrice: '0.950', total: '475.000'),
  );
  final shippingLarge = EstimateEntry(
    productName: 'أكياس الشحن',
    sizeLabel: '35*40',
    quantity: '1000',
    unitLabel: 'قطعة',
    quote: quote(quantity: '1000.000', unitPrice: '0.950', total: '950.000'),
  );
  final handles = EstimateEntry(
    productName: 'أكياس يد خارجية',
    sizeLabel: '40*40',
    quantity: '300',
    unitLabel: 'قطعة',
    quote: quote(quantity: '300.000', unitPrice: '1.400', total: '420.000'),
  );
  const handPriced = EstimateEntry(
    productName: 'أكياس ورقية 3D',
    sizeLabel: 'سادة',
    quantity: '200',
    unitLabel: 'قطعة',
  );

  group('estimateTotal', () {
    test('adds the server totals', () {
      // Act
      final total = estimateTotal([shippingSmall, shippingLarge, handles]);

      // Assert
      expect(total, '1845.000');
    });

    test('adds in thousandths, so fractions do not drift as doubles would', () {
      // Arrange — 0.1 + 0.2 is 0.30000000000000004 as a double.
      EstimateEntry line(String total) => EstimateEntry(
        productName: 'x',
        sizeLabel: 'y',
        quantity: '1',
        unitLabel: 'قطعة',
        quote: quote(quantity: '1.000', unitPrice: total, total: total),
      );

      // Act
      final total = estimateTotal([line('0.100'), line('0.200')]);

      // Assert
      expect(total, '0.300');
    });

    test('leaves a hand-priced line out, and is null when nothing has a price', () {
      // Act & Assert
      expect(estimateTotal([shippingSmall, handPriced]), '475.000');
      expect(estimateTotal([handPriced]), isNull);
    });
  });

  group('parseHandPrice', () {
    test('reads a typed price as money, and refuses what is not one', () {
      // Act & Assert
      expect(parseHandPrice('1.5'), '1.5');
      expect(parseHandPrice(' 2,25 '), '2.25');
      expect(parseHandPrice('3'), '3');
      expect(parseHandPrice(''), isNull);
      expect(parseHandPrice('0'), isNull);
      expect(parseHandPrice('1.2345'), isNull);
      expect(parseHandPrice('abc'), isNull);
    });
  });

  group('handLineTotal', () {
    test('drops the fraction of a dinar, as the order will', () {
      // Act & Assert — 333 × 1.5 = 499.5
      expect(handLineTotal(quantity: '333', unitPrice: '1.5'), '499.000');
    });

    test('never shows a line worth something as zero', () {
      // Act & Assert — 1 × 0.25
      expect(handLineTotal(quantity: '1', unitPrice: '0.25'), '1.000');
    });

    test('is null when the quantity is not a number', () {
      // Act & Assert
      expect(handLineTotal(quantity: '', unitPrice: '1'), isNull);
    });
  });

  group('priceEstimateMessage', () {
    test('a hand price is totalled like any other', () {
      // Arrange
      final priced = handPriced.copyWith(handUnitPrice: '1.5');

      // Act
      final message = priceEstimateMessage([shippingSmall, priced]);

      // Assert
      expect(message, contains('• سادة — 200 قطعة × 1.5 = 300 د.ل'));
      expect(message, contains('الإجمالي: 775 د.ل\n'));
      expect(message, isNot(contains('حسب الطلب')));
    });

    test('groups sizes under their product and ends on the total', () {
      // Act
      final message = priceEstimateMessage([shippingSmall, handles, shippingLarge]);

      // Assert — the second shipping size joins the first, not the end of the list.
      expect(
        message,
        'مرحباً، هذا عرض السعر المطلوب:\n'
        '\n'
        'أكياس الشحن\n'
        '• مقاس 25*35 — 500 قطعة × 0.95 = 475 د.ل\n'
        '• مقاس 35*40 — 1,000 قطعة × 0.95 = 950 د.ل\n'
        '\n'
        'أكياس يد خارجية\n'
        '• مقاس 40*40 — 300 قطعة × 1.4 = 420 د.ل\n'
        '\n'
        'الإجمالي: 1,845 د.ل\n'
        'الأسعار لا تشمل التوصيل.',
      );
    });

    test('says a hand-priced line has no figure, and that the total leaves it out', () {
      // Act
      final message = priceEstimateMessage([shippingSmall, handPriced]);

      // Assert
      expect(message, contains('• سادة — 200 قطعة — السعر حسب الطلب'));
      expect(message, contains('الإجمالي: 475 د.ل\n(لا يشمل الأصناف المسعّرة حسب الطلب)'));
    });

    test('has no total line when nothing on it is priced', () {
      // Act
      final message = priceEstimateMessage([handPriced]);

      // Assert
      expect(message, isNot(contains('الإجمالي')));
    });
  });
}
