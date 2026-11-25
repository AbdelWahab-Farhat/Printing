import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sales board's JSON seam: the per-size breakdown and the best sellers, tested against the
/// body `SalesStatisticsQuery` sends, and against the older body that had neither.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> board({List<dynamic>? byType, List<dynamic>? topItems}) => <String, dynamic>{
    'period': {'from': '2026-03-01', 'to': '2026-03-31'},
    'sales_value': {'plain': '960.00', 'printed': '1100.00', 'total': '2060.00'},
    'by_type': ?byType,
    'top_items': ?topItems,
    'weight_comparison': {
      'plain_kg': '30.000',
      'printed_kg': '20.000',
      'total_kg': '50.000',
      'printed_share_percent': '40.0',
      'weight_coverage_percent': '100.0',
    },
    'printed_pieces': {'count': 1000, 'weight_kg': '20.000'},
    'orders_counted': 1,
  };

  Map<String, dynamic> oldTypeRow() => <String, dynamic>{
    'type': 'كيس شحن',
    'value': '2060.00',
    'weight_kg': '50.000',
    'plain_kg': '30.000',
    'printed_kg': '20.000',
    'pieces': 1000,
  };

  test('a body from before sizes and best sellers still parses', () {
    // Arrange
    final json = board(byType: [oldTypeRow()]);

    // Act
    final statistics = SalesStatistics.fromJson(json);

    // Assert — empty lists, and a weight inferred from the figure the old body did send
    expect(statistics.topItems, isEmpty);
    expect(statistics.byType.single.sizes, isEmpty);
    expect(statistics.byType.single.hasWeight, isTrue);
  });

  test('a size nobody weighed keeps its missing figures null, not zero', () {
    // Arrange — a paper bag: counted, never weighed
    final json = board(
      byType: [
        {
          ...oldTypeRow(),
          'weight_kg': '0.000',
          'plain_value': '0.00',
          'printed_value': '622.50',
          'weighed': false,
          'sizes': [
            {
              'width_cm': 22,
              'height_cm': 26,
              'value': '622.50',
              'plain_value': '0.00',
              'printed_value': '622.50',
              'weight_kg': null,
              'plain_kg': null,
              'printed_kg': null,
              'pieces': 250,
            },
          ],
        },
      ],
    );

    // Act
    final type = SalesStatistics.fromJson(json).byType.single;

    // Assert
    expect(type.hasWeight, isFalse);
    expect(type.printedValue, '622.50');
    final size = type.sizes.single;
    expect(size.weightKg, isNull);
    expect(size.plainKg, isNull);
    expect(size.pieces, 250);
    expect(size.dimensions, '22×26');
  });

  test('the unsized row has no dimensions', () {
    // Arrange
    final json = board(
      byType: [
        {
          ...oldTypeRow(),
          'sizes': [
            {
              'width_cm': null,
              'height_cm': null,
              'value': '5000.00',
              'plain_value': '0.00',
              'printed_value': '5000.00',
            },
          ],
        },
      ],
    );

    // Act
    final size = SalesStatistics.fromJson(json).byType.single.sizes.single;

    // Assert
    expect(size.dimensions, isNull);
    expect(size.pieces, isNull);
  });

  test('a best seller reads its kind, size and share', () {
    // Arrange
    final json = board(
      byType: [oldTypeRow()],
      topItems: [
        {
          'product': 'أكياس شحن - سادة',
          'variant': 'كبير',
          'type': 'كيس شحن',
          'kind': 'plain',
          'width_cm': 45,
          'height_cm': 50,
          'value': '2000.00',
          'share_percent': '29.1',
          'weight_kg': '65.000',
          'pieces': null,
        },
        {
          'product': 'أكياس يد خارجية - مطبوعه',
          'variant': '30*30',
          'type': 'أكياس يد خارجية',
          'kind': 'printed',
          'width_cm': 30,
          'height_cm': 30,
          'value': '1642.00',
          'share_percent': '23.9',
          'weight_kg': null,
          'pieces': 1100,
        },
      ],
    );

    // Act
    final [plain, printed] = SalesStatistics.fromJson(json).topItems;

    // Assert
    expect(plain.kind, SaleKind.plain);
    expect(plain.dimensions, '45×50');
    expect(plain.variantIsDimensions, isFalse);
    expect(plain.sharePercent, '29.1');
    expect(plain.pieces, isNull);

    expect(printed.kind, SaleKind.printed);
    // «30*30» already is the size, so the screen shows the dimensions once rather than twice
    expect(printed.variantIsDimensions, isTrue);
    expect(printed.weightKg, isNull);
  });
}
