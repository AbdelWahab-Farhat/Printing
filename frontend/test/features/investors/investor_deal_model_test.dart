import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two figures that make the company a partner in a deal, as they come off the wire.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> dealJson({Map<String, dynamic> extra = const {}}) => {
    'id': 22,
    'code': 'D22',
    'status': 'open',
    'status_label': 'مفتوحة',
    'investor_profit_share_percent': '50.00',
    ...extra,
  };

  test('a deal born from an order carries the company stake and the funded fraction', () {
    // Arrange — the owner's example: 3,000 of 20,000.
    final json = dealJson(
      extra: {'company_stake': '17000.00', 'investor_funded_percent': '15.0000'},
    );

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert
    expect(deal.companyStake, '17000.00');
    expect(deal.investorFundedPercent, '15.0000');
  });

  test('a deal the server never said this about owns all of its goods', () {
    // Arrange — an older payload, or a deal built by hand.
    final json = dealJson();

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert — exactly what every deal was before the rule: nothing on the company, all of the
    // goods the partners'.
    expect(deal.companyStake, '0.00');
    expect(deal.investorFundedPercent, '100.0000');
  });

  test('a deal that sells its plain stock to the press carries the price it agreed', () {
    // Arrange
    final json = dealJson(extra: {'printing_sale_price': '32.000'});

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert
    expect(deal.printingSalePrice, '32.000');
  });

  test('a deal with no such term is left null rather than zeroed', () {
    // Arrange — every deal funded before the term existed, and every one funded without it.
    final json = dealJson();

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert — null is «no such arrangement», and a zero would read as «the press takes them for
    // nothing». The screen and the server both branch on exactly this.
    expect(deal.printingSalePrice, isNull);
  });

  test('a deal carries what its orders made it, on the road and at the door', () {
    // Arrange — two parcels delivered and one still out, as the server adds them up.
    final json = dealJson(
      extra: {
        'orders_profit': {
          'in_flight': {'orders': 1, 'profit': '3000.00'},
          'delivered': {'orders': 2, 'profit': '6000.00'},
          'total': {'orders': 3, 'profit': '9000.00'},
        },
      },
    );

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert
    expect(deal.ordersProfit?.inFlight.orders, 1);
    expect(deal.ordersProfit?.inFlight.profit, '3000.00');
    expect(deal.ordersProfit?.delivered.profit, '6000.00');
    expect(deal.ordersProfit?.total.profit, '9000.00');
  });

  test('a deal read off a list carries no order profit at all', () {
    // Arrange — the deals screen sends no such block; only the detail payload walks the orders.
    final json = dealJson();

    // Act
    final deal = InvestorDeal.fromJson(json);

    // Assert — null, not a row of zeros: «nobody asked» and «nothing was sold» are different
    // sentences, and the screen draws the section on the first of them by drawing nothing.
    expect(deal.ordersProfit, isNull);
  });
}