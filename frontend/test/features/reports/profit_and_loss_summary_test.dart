import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/reports/models/profit_and_loss_summary.dart';

/// The report as it arrives: three nested blocks and three loose figures.
///
/// The one piece of thinking in this model is that **nothing in it is derived**. The server sends
/// every figure, including the ones that look like sums of the others — and two of them are
/// deliberately not: the cost parts come from a different table than their total, and gross
/// profit is rounded once from unrounded inputs. A model that helpfully re-computed either would
/// put a number on screen the server never claimed.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The full payload, exactly as `ProfitAndLossSummaryQuery` builds it.
  const json = <String, dynamic>{
    'period': {'from': '2026-03-01', 'to': '2026-03-31'},
    'revenue': {'product': '12450.00', 'service': '300.00', 'total': '12750.00'},
    'cost_of_goods_sold': {
      'material': '4000.00',
      'labor': '900.00',
      'overhead': '350.00',
      'total': '5250.00',
    },
    'gross_profit': '7500.00',
    'cash_collected': '9100.00',
    'orders_recognized': 12,
  };

  group('parsing', () {
    test('reads all three blocks and the three figures beside them', () {
      // Arrange - the payload above

      // Act
      final summary = ProfitAndLossSummary.fromJson(json);

      // Assert
      expect(summary.period.from, '2026-03-01');
      expect(summary.period.to, '2026-03-31');
      expect(summary.revenue.product, '12450.00');
      expect(summary.revenue.service, '300.00');
      expect(summary.revenue.total, '12750.00');
      expect(summary.costOfGoodsSold.material, '4000.00');
      expect(summary.costOfGoodsSold.labor, '900.00');
      expect(summary.costOfGoodsSold.overhead, '350.00');
      expect(summary.costOfGoodsSold.total, '5250.00');
      expect(summary.grossProfit, '7500.00');
      expect(summary.cashCollected, '9100.00');
      expect(summary.ordersRecognized, 12);
    });

    test('every money figure stays the string the server sent', () {
      // Arrange

      // Act
      final summary = ProfitAndLossSummary.fromJson(json);

      // Assert — a `double` here is the first step towards this app re-deriving a figure it has
      // no business computing, and `'12450.00'` through a float is how a report grows a cent
      expect(summary.revenue.total, isA<String>());
      expect(summary.costOfGoodsSold.total, isA<String>());
      expect(summary.grossProfit, isA<String>());
      expect(summary.cashCollected, isA<String>());
      expect(summary.ordersRecognized, isA<int>());
    });

    test('a period nothing was delivered in reads as zeros, not as a gap', () {
      // Arrange — the server builds this as a plain array, so every key is present whatever
      // the answer is
      const empty = <String, dynamic>{
        'period': {'from': '2026-04-01', 'to': '2026-04-30'},
        'revenue': {'product': '0.00', 'service': '0.00', 'total': '0.00'},
        'cost_of_goods_sold': {
          'material': '0.00',
          'labor': '0.00',
          'overhead': '0.00',
          'total': '0.00',
        },
        'gross_profit': '0.00',
        'cash_collected': '0.00',
        'orders_recognized': 0,
      };

      // Act
      final summary = ProfitAndLossSummary.fromJson(empty);

      // Assert
      expect(summary.grossProfit, '0.00');
      expect(summary.hasRecognisedOrders, isFalse);
    });

    test('a period with no deliveries can still have taken money', () {
      // Arrange — a deposit against a job still in printing: an ordinary state, not a
      // contradiction the screen should try to hide
      const deposits = <String, dynamic>{
        'period': {'from': '2026-04-01', 'to': '2026-04-30'},
        'revenue': {'product': '0.00', 'service': '0.00', 'total': '0.00'},
        'cost_of_goods_sold': {
          'material': '0.00',
          'labor': '0.00',
          'overhead': '0.00',
          'total': '0.00',
        },
        'gross_profit': '0.00',
        'cash_collected': '150.00',
        'orders_recognized': 0,
      };

      // Act
      final summary = ProfitAndLossSummary.fromJson(deposits);

      // Assert
      expect(summary.ordersRecognized, 0);
      expect(summary.cashCollected, '150.00');
    });
  });

  group('nothing is re-derived', () {
    test('the cost total is the one the server sent, not the sum of its parts', () {
      // Arrange — the three parts come from `order_items` and the total from a cached column on
      // the orders, so they are allowed to disagree
      const mismatched = <String, dynamic>{
        'period': {'from': '2026-03-01', 'to': '2026-03-31'},
        'revenue': {'product': '300.00', 'service': '0.00', 'total': '300.00'},
        'cost_of_goods_sold': {
          'material': '80.00',
          'labor': '30.00',
          'overhead': '10.00',
          'total': '125.00',
        },
        'gross_profit': '175.00',
        'cash_collected': '0.00',
        'orders_recognized': 1,
      };

      // Act
      final summary = ProfitAndLossSummary.fromJson(mismatched);

      // Assert — 80 + 30 + 10 is 120, and the total is still 125
      expect(summary.costOfGoodsSold.total, '125.00');
    });

    test('gross profit is read, not subtracted', () {
      // Arrange — the server subtracts the *unrounded* cost and rounds once, so a subtraction
      // repeated here would be a second answer to a question that already has one
      const roundedOnce = <String, dynamic>{
        'period': {'from': '2026-03-01', 'to': '2026-03-31'},
        'revenue': {'product': '350.00', 'service': '0.00', 'total': '350.00'},
        'cost_of_goods_sold': {
          'material': '120.00',
          'labor': '0.00',
          'overhead': '0.00',
          'total': '120.00',
        },
        'gross_profit': '229.99',
        'cash_collected': '0.00',
        'orders_recognized': 1,
      };

      // Act
      final summary = ProfitAndLossSummary.fromJson(roundedOnce);

      // Assert
      expect(summary.grossProfit, '229.99');
    });
  });

  group('what the screen asks the model', () {
    test('the headline figure is grouped, and keeps its sign', () {
      // Arrange
      const summary = ProfitAndLossSummary(
        period: PnlPeriod(from: '2026-03-01', to: '2026-03-31'),
        revenue: PnlRevenue(product: '0.00', service: '0.00', total: '0.00'),
        costOfGoodsSold: PnlCostOfGoodsSold(
          material: '0.00',
          labor: '0.00',
          overhead: '0.00',
          total: '12450.00',
        ),
        grossProfit: '-12450.00',
        cashCollected: '0.00',
        ordersRecognized: 3,
      );

      // Act
      final label = summary.grossProfitLabel;

      // Assert — 12450 is a shape, 12,450 is a number
      expect(label, '-12,450');
    });

    test('a negative gross profit is a loss the screen has to be able to say', () {
      // Arrange
      const losing = ProfitAndLossSummary(
        period: PnlPeriod(from: '2026-03-01', to: '2026-03-31'),
        revenue: PnlRevenue(product: '75.00', service: '0.00', total: '75.00'),
        costOfGoodsSold: PnlCostOfGoodsSold(
          material: '120.00',
          labor: '0.00',
          overhead: '0.00',
          total: '120.00',
        ),
        grossProfit: '-45.00',
        cashCollected: '0.00',
        ordersRecognized: 1,
      );

      // Act & Assert
      expect(losing.isLoss, isTrue);
    });

    test('a figure that cannot be read is not called a loss', () {
      // Arrange — `num.tryParse` only ever asks a question here; painting «خسارة» over a number
      // nobody could parse is the worse of the two mistakes
      const odd = ProfitAndLossSummary(
        period: PnlPeriod(from: '2026-03-01', to: '2026-03-31'),
        revenue: PnlRevenue(product: '0.00', service: '0.00', total: '0.00'),
        costOfGoodsSold: PnlCostOfGoodsSold(
          material: '0.00',
          labor: '0.00',
          overhead: '0.00',
          total: '0.00',
        ),
        grossProfit: '',
        cashCollected: '0.00',
        ordersRecognized: 0,
      );

      // Act & Assert
      expect(odd.isLoss, isFalse);
    });

    test('the period says both of its ends, because both are included', () {
      // Arrange
      const period = PnlPeriod(from: '2026-03-01', to: '2026-03-31');

      // Act
      final label = period.label;

      // Assert
      expect(label, 'من 2026-03-01 إلى 2026-03-31');
    });
  });
}
