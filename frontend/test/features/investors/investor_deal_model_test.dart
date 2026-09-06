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
}
