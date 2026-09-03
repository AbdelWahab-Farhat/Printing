import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a day header goes on a feed read newest first: above the first row of each day.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('the first row of the feed starts a day', () {
    // Arrange
    final at = DateTime(2026, 9, 2, 22, 13);

    // Act
    final starts = startsNewDay(null, at);

    // Assert
    expect(starts, isTrue);
  });

  test('a row on the same day as the one above it does not', () {
    // Arrange
    final above = DateTime(2026, 9, 2, 22, 13);
    final at = DateTime(2026, 9, 2, 7, 4);

    // Act
    final starts = startsNewDay(above, at);

    // Assert
    expect(starts, isFalse);
  });

  test('the first row of an earlier day does', () {
    // Arrange
    final above = DateTime(2026, 9, 2, 7, 4);
    final at = DateTime(2026, 9, 1, 23, 59);

    // Act
    final starts = startsNewDay(above, at);

    // Assert
    expect(starts, isTrue);
  });
}
