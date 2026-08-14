import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:flutter_test/flutter_test.dart';

/// معدل تكلفة تصنيع, as it arrives and as the screens read it.
///
/// **`product` and `product_variant` are always sent, and `null` is an answer.** Every endpoint
/// eager-loads both relations, so a null there means «this rate is not on that rung» — never «the
/// server did not include it». That is what makes the rung derivable from the payload alone.
///
/// The other thing pinned here is that a kind of cost this build has never heard of parses into
/// [ManufacturingCostType.unknown] rather than throwing: one new case on the server must not turn
/// a whole page of rates into a parse failure, and the row still reads correctly because the
/// Arabic on it is the server's own.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> json({
    Object? product,
    Object? productVariant,
    String costType = 'labor',
    String costTypeLabel = 'عمالة',
    String ratePerUnit = '3.500',
  }) => <String, dynamic>{
    'id': 7,
    'product': product,
    'product_variant': productVariant,
    'cost_type': costType,
    'cost_type_label': costTypeLabel,
    'rate_per_unit': ratePerUnit,
    'is_active': true,
    'notes': null,
  };

  group('parsing', () {
    test('a rate on no particular rung is the default one', () {
      // Arrange
      final payload = json();

      // Act
      final rate = ManufacturingCostRate.fromJson(payload);

      // Assert
      expect(rate.scope, RateScope.standard);
      expect(rate.scopeId, isNull);
      expect(rate.scopeLabel, 'افتراضي');
    });

    test('a product-wide rate reads its product from the key the server sends', () {
      // Arrange
      final payload = json(product: {'id': 3, 'name': 'كيس ورقي'});

      // Act
      final rate = ManufacturingCostRate.fromJson(payload);

      // Assert
      expect(rate.scope, RateScope.product);
      expect(rate.scopeId, 3);
      expect(rate.scopeLabel, 'كيس ورقي');
    });

    test('a size-scoped rate outranks the product one it sits above', () {
      // Arrange — the API never sends both, but the size is the narrower rung either way.
      final payload = json(productVariant: {'id': 11, 'label': '25*35'});

      // Act
      final rate = ManufacturingCostRate.fromJson(payload);

      // Assert
      expect(rate.scope, RateScope.variant);
      expect(rate.scopeId, 11);
    });

    test('the rate stays the string the server sent', () {
      // Arrange
      final payload = json(ratePerUnit: '0.850');

      // Act
      final rate = ManufacturingCostRate.fromJson(payload);

      // Assert — parsing it into a double to hold it is how `0.850` reaches a screen as
      // `0.8500000000000001`.
      expect(rate.ratePerUnit, '0.850');
      expect(rate.ratePerUnit, isA<String>());
      expect(rate.rateLabel, '0.85');
    });

    test('a kind of cost this build has never heard of does not take the page down', () {
      // Arrange — a fifth case added on the server, months after this build shipped.
      final payload = json(costType: 'quality_control', costTypeLabel: 'ضبط الجودة');

      // Act
      final rate = ManufacturingCostRate.fromJson(payload);

      // Assert — unreadable to the code, perfectly readable on screen.
      expect(rate.costType, ManufacturingCostType.unknown);
      expect(rate.costTypeLabel, 'ضبط الجودة');
    });
  });

  group('the kinds of cost', () {
    test('scrap loss is the one kind nothing ever reads', () {
      // Arrange & Act & Assert — the API stores such a rate and then never consults it: a scrap
      // loss is priced from the FIFO cost of the stock actually written off.
      expect(ManufacturingCostType.scrapLoss.isRateDriven, isFalse);
      expect(ManufacturingCostType.labor.isRateDriven, isTrue);
      expect(ManufacturingCostType.machineRuntime.isRateDriven, isTrue);
      expect(ManufacturingCostType.overhead.isRateDriven, isTrue);
    });

    test('a kind this build has never heard of is not written off as never applied', () {
      // Arrange & Act & Assert — «لا يُطبَّق» is a claim about the server's behaviour, and the
      // one kind this app may make it about is the one it knows the server ignores. A cost type
      // added next month parses as [unknown], and an allowlist would have labelled it as never
      // applied on a screen that has no way of knowing that.
      expect(ManufacturingCostType.unknown.isRateDriven, isTrue);
    });

    test('the form offers three kinds and the filter names four', () {
      // Arrange & Act & Assert — a legacy scrap-loss row is still filtered for and still shown;
      // it is only creating a new one that is left out.
      expect(ManufacturingCostType.offered, hasLength(3));
      expect(ManufacturingCostType.offered, isNot(contains(ManufacturingCostType.scrapLoss)));
      expect(ManufacturingCostType.choices, hasLength(4));
      expect(ManufacturingCostType.choices, isNot(contains(ManufacturingCostType.unknown)));
    });

    test('a wire value the app cannot read answers with the fallback, not a throw', () {
      // Arrange & Act & Assert
      expect(
        ManufacturingCostType.fromWire('machine_runtime'),
        ManufacturingCostType.machineRuntime,
      );
      expect(ManufacturingCostType.fromWire('quality_control'), ManufacturingCostType.unknown);
      expect(ManufacturingCostType.fromWire(null), ManufacturingCostType.unknown);
    });
  });
}
