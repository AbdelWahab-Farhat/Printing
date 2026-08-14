import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// The five numbers at the top of the balances screen.
///
/// The one piece of thinking in this model is that **the server's two attention counts overlap
/// and the bar's three segments must not**. A shelf at zero that somebody asked to be warned
/// about is both low and empty; drawing it twice would make the bar wider than the warehouse.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('parsing', () {
    test("reads the server's five numbers", () {
      // Arrange
      const json = {
        'total_lines': 24,
        'total_quantity': '12450.000',
        'low_stock_count': 4,
        'out_of_stock_count': 2,
        'healthy_count': 18,
      };

      // Act
      final summary = WarehouseStockSummary.fromJson(json);

      // Assert
      expect(summary.totalLines, 24);
      expect(summary.totalQuantity, '12450.000');
      expect(summary.lowStockCount, 4);
      expect(summary.outOfStockCount, 2);
      expect(summary.healthyCount, 18);
    });

    test('a warehouse nothing has arrived at reads as zeros, not as a failure', () {
      // Arrange
      const json = {
        'total_lines': 0,
        'total_quantity': '0.000',
        'low_stock_count': 0,
        'out_of_stock_count': 0,
        'healthy_count': 0,
      };

      // Act
      final summary = WarehouseStockSummary.fromJson(json);

      // Assert
      expect(summary.totalLines, 0);
      expect(summary.hasLines, isFalse);
    });
  });

  group('the label', () {
    test("drops the database's decimals and groups the digits", () {
      // Arrange
      const summary = WarehouseStockSummary(totalLines: 3, totalQuantity: '12450.000');

      // Act
      final label = summary.totalQuantityLabel;

      // Assert — 12450 is a shape, 12,450 is a number
      expect(label, '12,450');
    });

    test('keeps a real fraction rather than rounding it away', () {
      // Arrange
      const summary = WarehouseStockSummary(totalLines: 1, totalQuantity: '1250.500');

      // Act
      final label = summary.totalQuantityLabel;

      // Assert
      expect(label, '1,250.5');
    });
  });

  group("the bar's segments", () {
    test('the middle segment is what is low and not also empty', () {
      // Arrange — 24 lines: 18 fine, 2 empty, 4 low, and one of those 4 is one of the 2
      const summary = WarehouseStockSummary(
        totalLines: 24,
        totalQuantity: '12450.000',
        lowStockCount: 4,
        outOfStockCount: 2,
        healthyCount: 18,
      );

      // Act
      final lowOnly = summary.lowOnlyCount;

      // Assert — 18 + 4 + 2 = 24, so exactly one line is counted in both server numbers
      expect(lowOnly, 4);
      expect(summary.healthyCount + lowOnly + summary.outOfStockCount, summary.totalLines);
    });

    test('an empty shelf with a threshold is drawn once, as empty', () {
      // Arrange — the one line is both low and out
      const summary = WarehouseStockSummary(
        totalLines: 1,
        totalQuantity: '0.000',
        lowStockCount: 1,
        outOfStockCount: 1,
      );

      // Act
      final lowOnly = summary.lowOnlyCount;

      // Assert
      expect(lowOnly, 0);
      expect(summary.healthyCount + lowOnly + summary.outOfStockCount, summary.totalLines);
    });

    test('a summary that does not add up cannot produce a negative segment', () {
      // Arrange — nothing should send this, and a bar drawn backwards is not the way to find out
      const summary = WarehouseStockSummary(
        totalLines: 2,
        totalQuantity: '0.000',
        lowStockCount: 9,
        outOfStockCount: 9,
        healthyCount: 9,
      );

      // Act
      final lowOnly = summary.lowOnlyCount;

      // Assert
      expect(lowOnly, 0);
    });
  });
}
