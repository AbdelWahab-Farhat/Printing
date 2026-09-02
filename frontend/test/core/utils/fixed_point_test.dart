import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ledger's arithmetic, done in thousandths rather than in `double`.
///
/// The number that motivated this: a count that took a shelf from 105,250 to 0 has to read
/// «كان 105,250» on the row, and a screen subtracting `-105250.000` from `0.000` in floating
/// point is one rounding away from printing `105,249.999`.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('a decimal string round-trips through thousandths at any scale', () {
    // Arrange
    const value = '1050.25';

    // Act
    final milli = thousandths(value);

    // Assert
    expect(milli, BigInt.from(1050250));
    expect(fromThousandths(milli), '1050.250');
    expect(fromThousandths(milli, scale: 2), '1050.25');
    expect(fromThousandths(milli, scale: 0), '1050');
  });

  test('a negative survives, and a negative that rounds to nothing does not keep its sign', () {
    // Arrange
    final debt = thousandths('-300');
    final dust = thousandths('-0.004');

    // Act + Assert
    expect(fromThousandths(debt), '-300.000');
    expect(fromThousandths(dust, scale: 2), '0.00');
  });

  test('quantity times unit cost is money to two places, rounded half away from zero', () {
    // Arrange
    const remaining = '300.000';
    const unitCost = '3.500';

    // Act
    final value = multiplyToMoney(remaining, unitCost);

    // Assert
    expect(value, '1050.00');
    expect(multiplyToMoney('1', '0.005'), '0.01');
    expect(multiplyToMoney('0.000', '3.500'), '0.00');
  });

  test('money over quantity is a unit cost to three places, and nothing over nothing', () {
    // Arrange — what FIFO charged 150 units drawn from 100 @ 10 and 50 @ 20
    const total = '2000.00';
    const quantity = '150.000';

    // Act
    final unit = divideToUnitCost(total, quantity);

    // Assert
    expect(unit, '13.333');
    expect(divideToUnitCost('10.00', '0.000'), isNull);
  });

  test('the balance before a count is the balance after it less the signed change', () {
    // Arrange — the screenshot's adjustment: the shelf went to 0 by a change of −105,250
    const after = '0.000';
    const signed = '-105250.000';

    // Act
    final before = subtractDecimals(after, signed);

    // Assert
    expect(before, '105250.000');
    expect(addDecimals('1000.000', '300.000'), '1300.000');
  });
}
