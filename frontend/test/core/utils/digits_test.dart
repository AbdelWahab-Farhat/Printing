import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three functions with three jobs, and the whole point of testing them together is that the
/// boundaries between the jobs stay where they are: [GroupedDigits.grouped] and
/// [GroupedNumberText.grouped] only ever *add* separators, [trimDecimals] only ever *removes*
/// zeros, and [groupedDecimal] is the two of them in that order.
///
/// Arrange - Act - Assert throughout, matching the backend's standard.
void main() {
  group('int.grouped', () {
    test('groups a number in threes from the right', () {
      // Arrange
      const value = 2975;

      // Act
      final label = value.grouped;

      // Assert
      expect(label, '2,975');
    });

    test('leaves anything under a thousand alone', () {
      expect(0.grouped, '0');
      expect(9.grouped, '9');
      expect(999.grouped, '999');
    });

    test('groups every three digits, however many there are', () {
      expect(1000.grouped, '1,000');
      expect(12450.grouped, '12,450');
      expect(1234567.grouped, '1,234,567');
    });

    test('keeps the minus outside the grouping', () {
      // Arrange
      const value = -12450;

      // Act
      final label = value.grouped;

      // Assert
      expect(label, '-12,450');
    });
  });

  group('String.grouped', () {
    test('groups the whole part and cuts the padding the server pads money with', () {
      // Arrange — two decimals is how the server sends money, and «.00» is noise on a screen.
      const value = '2975.00';

      // Act
      final label = value.grouped;

      // Assert
      expect(label, '2,975');
    });

    test('keeps the decimals that carry a value, and drops only the padding', () {
      expect('0.850'.grouped, '0.85');
      expect('1250.500'.grouped, '1,250.5');
      expect('0.125'.grouped, '0.125');
    });

    test('groups a whole number with no fraction at all', () {
      expect('2975'.grouped, '2,975');
      expect('1234567'.grouped, '1,234,567');
    });

    test('keeps the minus outside the grouping', () {
      expect('-12450.00'.grouped, '-12,450');
    });

    test('survives a value too long for an int', () {
      // A quantity is never worth taking a screen down for, so this is string surgery and a
      // twenty-digit figure groups like any other.
      expect('123456789012345678901'.grouped, '123,456,789,012,345,678,901');
    });

    test('leaves a value that is not a number alone', () {
      expect(''.grouped, '');
      expect('—'.grouped, '—');
    });
  });

  group('trimDecimals', () {
    test('drops the zeros a database pads with, and the point with them', () {
      expect(trimDecimals('100.000'), '100');
      expect(trimDecimals('0.850'), '0.85');
    });

    test('leaves a value with no fraction alone', () {
      expect(trimDecimals('100'), '100');
    });

    test('adds no separators — this is what goes back into a text field', () {
      // Arrange — a comma here would be read back as a decimal point on an Arabic keyboard.
      const value = '12450.000';

      // Act
      final text = trimDecimals(value);

      // Assert
      expect(text, '12450');
    });
  });

  group('unsigned', () {
    test('takes the minus off a loss, so the word in front of it can carry the sign', () {
      // Arrange — «خسارة -1,500 د.ل» says the direction twice, and twice reads as a negative
      // loss, which is a profit.
      const loss = '-1500.00';

      // Act
      final size = unsigned(loss);

      // Assert
      expect(size, '1500.00');
    });

    test('leaves a positive figure exactly as the server sent it', () {
      // Arrange
      const profit = '1500.00';

      // Act & Assert
      expect(unsigned(profit), '1500.00');
    });

    test('a bare minus with nothing after it is not mistaken for a number', () {
      // Arrange — an em dash and an empty string reach these helpers from screens that have
      // nothing to draw, and must come back out unchanged rather than throwing.
      // Act & Assert
      expect(unsigned('–'), '–');
      expect(unsigned(''), '');
    });
  });

  group('groupedDecimal', () {
    test('trims first, then groups', () {
      expect(groupedDecimal('12450.000'), '12,450');
      expect(groupedDecimal('1250.500'), '1,250.5');
    });

    test('reads a loss as a loss', () {
      expect(groupedDecimal('-12450.00'), '-12,450');
    });
  });
}
