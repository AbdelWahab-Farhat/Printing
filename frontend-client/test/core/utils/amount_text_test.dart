import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:flutter_test/flutter_test.dart';

/// «٢٬٠٠٠ × ١٫٤٠ د.ل» لا «2000.000 × 1.400».
///
/// The API declares quantities at three places and money at two, and both arrive padded. These
/// pin the one rule that matters about taking the padding off: **only zeros go.** A digit
/// somebody entered must survive, and a half must never be rounded away on a screen that says
/// «المتبقّي».
///
/// Arrange - Act - Assert throughout.
void main() {
  group('asQuantity', () {
    test('drops the scale the column was declared at', () {
      // Arrange - Act - Assert
      expect('2000.000'.asQuantity, '2,000');
      expect('500.000'.asQuantity, '500');
    });

    test('keeps a fraction somebody actually entered', () {
      // Arrange — half a kilo is half a kilo; what goes is padding, not meaning.
      expect('1.500'.asQuantity, '1.5');
      expect('0.250'.asQuantity, '0.25');
    });

    test('groups thousands and leaves smaller numbers alone', () {
      // Arrange - Act - Assert
      expect('999'.asQuantity, '999');
      expect('1000'.asQuantity, '1,000');
      expect('10000.000'.asQuantity, '10,000');
      expect('1234567'.asQuantity, '1,234,567');
    });

    test('a negative keeps its sign outside the grouping', () {
      // Arrange — a discount, drawn as a subtraction.
      expect('-1000.00'.asQuantity, '-1,000');
    });

    test('a value with no point is returned grouped and otherwise untouched', () {
      // Arrange - Act - Assert
      expect('0'.asQuantity, '0');
    });
  });

  group('asMoney', () {
    test('drops a fraction that is only zeros', () {
      // Arrange - Act - Assert
      expect('4330.00'.asMoney, '4,330');
    });

    test('never rounds a real fraction away', () {
      // Arrange — the failure this exists to prevent: «المتبقّي ١٬٨٨١» on an invoice that says
      // 1,880.50.
      expect('1880.50'.asMoney, '1,880.50');
      expect('1880.55'.asMoney, '1,880.55');
      expect('0.85'.asMoney, '0.85');
    });

    test('a fraction is kept at two places, unlike a quantity', () {
      // Arrange — a unit price is «١٫٤٠ د.ل», not «١٫٤»: the second is the column's scale
      // showing through, and the two are the same price written differently.
      expect('1.400'.asMoney, '1.40');
      expect('1.400'.asQuantity, '1.4');
    });
  });

  group('asPlainNumber', () {
    test('takes the padding off and puts no separator on', () {
      // Arrange — this one seeds a text field, and a grouped number is not a number: it fails
      // the field's own `[0-9.]` formatter, and would be refused by the server if it reached
      // the wire.
      expect('100.000'.asPlainNumber, '100');
      expect('2000.000'.asPlainNumber, '2000');
      expect('1.500'.asPlainNumber, '1.5');
    });

    test('what it produces still parses as a decimal', () {
      // Arrange - Act - Assert — the property that matters, stated as one.
      for (final value in ['100.000', '2000.000', '1.500', '0.250', '999999']) {
        expect(double.tryParse(value.asPlainNumber), isNotNull, reason: value);
      }
    });
  });

  test('the formatters are for drawing only and never feed the arithmetic', () {
    // Arrange — a guard on the boundary rather than on a value: grouped text is not a decimal
    // string, and `thousandths` must never be handed one.
    const grouped = '4,330';

    // Act - Assert — it would parse as nonsense, so the test states the rule the comment makes.
    expect(() => thousandths(grouped), throwsFormatException);
  });
}
