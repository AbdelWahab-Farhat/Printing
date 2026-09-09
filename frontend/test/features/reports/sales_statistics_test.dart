import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board as it arrives: four nested blocks, a list, and one loose integer.
///
/// **The one piece of thinking in this model is that nothing in it is derived** — and unlike
/// الأرباح والخسائر, here the parts genuinely do add up. That is a fact about the server's
/// arithmetic, not a licence for this app to redo it: every figure is read from the key that
/// carries it, نسبة المطبوع most of all, because a division repeated on two rounded weights is
/// how a screen ends up disagreeing with itself by a tenth.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The full payload, exactly as `SalesStatisticsQuery` builds it — the production figures from
  /// `SALES-STATISTICS-FRONTEND-INTEGRATION.md` §1.
  const json = <String, dynamic>{
    'period': {'from': '2026-08-01', 'to': '2026-09-08'},
    'sales_value': {'plain': '5626.40', 'printed': '8193.00', 'total': '13819.40'},
    'by_type': [
      {
        'type': 'أكياس الشحن',
        'value': '9157.90',
        'weight_kg': '294.700',
        'plain_kg': '111.200',
        'printed_kg': '183.500',
        'pieces': 4150,
      },
      {
        'type': 'أكياس ورقية عادية -',
        'value': '1072.50',
        'weight_kg': '0.000',
        'plain_kg': '0.000',
        'printed_kg': '0.000',
        'pieces': 400,
      },
    ],
    'weight_comparison': {
      'plain_kg': '154.200',
      'printed_kg': '211.100',
      'total_kg': '365.300',
      'printed_share_percent': '57.8',
      'weight_coverage_percent': '92.2',
    },
    'printed_pieces': {'count': 5270, 'weight_kg': '211.100'},
    'orders_counted': 32,
  };

  group('parsing', () {
    test('reads every block and the integer beside them', () {
      // Arrange - the payload above

      // Act
      final statistics = SalesStatistics.fromJson(json);

      // Assert
      expect(statistics.period.from, '2026-08-01');
      expect(statistics.period.to, '2026-09-08');
      expect(statistics.salesValue.plain, '5626.40');
      expect(statistics.salesValue.printed, '8193.00');
      expect(statistics.salesValue.total, '13819.40');
      expect(statistics.weightComparison.plainKg, '154.200');
      expect(statistics.weightComparison.printedKg, '211.100');
      expect(statistics.weightComparison.totalKg, '365.300');
      expect(statistics.weightComparison.printedSharePercent, '57.8');
      expect(statistics.weightComparison.weightCoveragePercent, '92.2');
      expect(statistics.printedPieces.count, 5270);
      expect(statistics.printedPieces.weightKg, '211.100');
      expect(statistics.ordersCounted, 32);
    });

    test('reads the type rows in the order the server sorted them', () {
      // Arrange - heaviest first is the server's own sort

      // Act
      final statistics = SalesStatistics.fromJson(json);

      // Assert
      expect(statistics.byType, hasLength(2));
      expect(statistics.byType.first.type, 'أكياس الشحن');
      expect(statistics.byType.first.weightKg, '294.700');
      expect(statistics.byType.first.plainKg, '111.200');
      expect(statistics.byType.first.printedKg, '183.500');
      expect(statistics.byType.first.value, '9157.90');
      expect(statistics.byType.first.pieces, 4150);
    });

    test('keeps the untidy label exactly as the server sent it', () {
      // Arrange — several shelves were auto-created from product names and carry a trailing dash.
      // Trimming it here would hide a naming problem that also shows on the inventory screens.

      // Act
      final statistics = SalesStatistics.fromJson(json);

      // Assert
      expect(statistics.byType.last.type, 'أكياس ورقية عادية -');
    });

    test('every money and weight figure stays the string the server sent', () {
      // Arrange

      // Act
      final statistics = SalesStatistics.fromJson(json);

      // Assert — a `double` here is the first step towards this app re-deriving a figure it has
      // no business computing, and `'365.300'` through a float is how a weight grows a gram
      expect(statistics.salesValue.total, isA<String>());
      expect(statistics.weightComparison.totalKg, isA<String>());
      expect(statistics.weightComparison.printedSharePercent, isA<String>());
      expect(statistics.printedPieces.weightKg, isA<String>());
    });

    test('an empty period parses to zeroes and an empty table, never to nulls', () {
      // Arrange — a real month in which nothing was delivered
      const empty = <String, dynamic>{
        'period': {'from': '2026-03-01', 'to': '2026-03-31'},
        'sales_value': {'plain': '0.00', 'printed': '0.00', 'total': '0.00'},
        'by_type': <dynamic>[],
        'weight_comparison': {
          'plain_kg': '0.000',
          'printed_kg': '0.000',
          'total_kg': '0.000',
          'printed_share_percent': '0.0',
          'weight_coverage_percent': '0.0',
        },
        'printed_pieces': {'count': 0, 'weight_kg': '0.000'},
        'orders_counted': 0,
      };

      // Act
      final statistics = SalesStatistics.fromJson(empty);

      // Assert
      expect(statistics.byType, isEmpty);
      expect(statistics.salesValue.total, '0.00');
      expect(statistics.hasCountedOrders, isFalse);
    });
  });

  group('hasCountedOrders', () {
    test('is true when the board is about anything at all', () {
      // Arrange - the payload above

      // Act
      final statistics = SalesStatistics.fromJson(json);

      // Assert
      expect(statistics.hasCountedOrders, isTrue);
    });
  });

  group('isFullyCovered', () {
    test('is false below 100, which is when the caveat is worth drawing', () {
      // Arrange
      const weight = WeightComparison(
        plainKg: '154.200',
        printedKg: '211.100',
        totalKg: '365.300',
        printedSharePercent: '57.8',
        weightCoveragePercent: '92.2',
      );

      // Act - the getter

      // Assert
      expect(weight.isFullyCovered, isFalse);
    });

    test('is true at 100, where the figure is noise', () {
      // Arrange
      const weight = WeightComparison(
        plainKg: '0.000',
        printedKg: '20.500',
        totalKg: '20.500',
        printedSharePercent: '100.0',
        weightCoveragePercent: '100.0',
      );

      // Act - the getter

      // Assert
      expect(weight.isFullyCovered, isTrue);
    });

    test('counts a figure it cannot read as covered rather than caveating blindly', () {
      // Arrange — painting a caveat over figures nobody could measure is the worse of the two
      // mistakes
      const weight = WeightComparison(
        plainKg: '0.000',
        printedKg: '0.000',
        totalKg: '0.000',
        printedSharePercent: '0.0',
        weightCoveragePercent: '—',
      );

      // Act - the getter

      // Assert
      expect(weight.isFullyCovered, isTrue);
    });
  });

  group('hasWeight', () {
    test('is false for a shelf counted by the piece, which still earned money', () {
      // Arrange — أكياس ورقية عادية: real value, no weight, and the row must still be drawn
      final statistics = SalesStatistics.fromJson(json);

      // Act
      final row = statistics.byType.last;

      // Assert
      expect(row.hasWeight, isFalse);
      expect(row.value, '1072.50');
      expect(row.pieces, 400);
    });

    test('is true for a material that was weighed', () {
      // Arrange
      final statistics = SalesStatistics.fromJson(json);

      // Act
      final row = statistics.byType.first;

      // Assert
      expect(row.hasWeight, isTrue);
    });
  });

  group('labels', () {
    test('the period reads as the window the server actually used', () {
      // Arrange
      final statistics = SalesStatistics.fromJson(json);

      // Act
      final label = statistics.period.label;

      // Assert
      expect(label, 'من 2026-08-01 إلى 2026-09-08');
    });

    test('a piece count is grouped like every other figure on the screen', () {
      // Arrange
      final statistics = SalesStatistics.fromJson(json);

      // Act
      final label = statistics.printedPieces.countLabel;

      // Assert
      expect(label, '5,270');
    });
  });
}
