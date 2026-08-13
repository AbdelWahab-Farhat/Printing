import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository.dart';
import 'package:printing/features/manufacturing_cost_rates/usecases/manufacturing_cost_rate_usecases.dart';

/// What the rate form's answers turn into before they reach the wire.
///
/// **Two conversions live here and nowhere else**, which is why this test exists without a widget
/// tree:
///
///   * `٣٫٥` is what a Libyan keyboard produces and every numeric rule on the server is
///     ASCII-only. A rate typed on the shop's own phone would otherwise be «المعدل يجب أن يكون
///     رقماً» with the number plainly on screen.
///   * the rung decides which id travels. The form remembers a chosen product *and* a chosen size
///     at once, so tapping through the three chips does not lose either answer — and exactly one
///     id is put on the wire here. Sending both is refused by a database CHECK constraint; the
///     default rung is the one with neither, so a leftover id is not a harmless extra but a rate
///     pinned to the wrong thing.
///
/// Arrange - Act - Assert throughout.
class _MockManufacturingCostRateRepository extends Mock
    implements ManufacturingCostRateRepository {}

void main() {
  late _MockManufacturingCostRateRepository repository;
  late SaveManufacturingCostRate saveRate;

  const stored = ManufacturingCostRate(
    id: 7,
    costType: ManufacturingCostType.labor,
    costTypeLabel: 'عمالة',
    ratePerUnit: '3.500',
  );

  setUpAll(() => registerFallbackValue(ManufacturingCostType.labor));

  setUp(() {
    repository = _MockManufacturingCostRateRepository();
    when(
      () => repository.create(
        costType: any(named: 'costType'),
        ratePerUnit: any(named: 'ratePerUnit'),
        productId: any(named: 'productId'),
        productVariantId: any(named: 'productVariantId'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => const Right(stored));
    when(
      () => repository.update(
        any(),
        costType: any(named: 'costType'),
        ratePerUnit: any(named: 'ratePerUnit'),
        productId: any(named: 'productId'),
        productVariantId: any(named: 'productVariantId'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    saveRate = SaveManufacturingCostRate(repository);
  });

  /// The rate the repository was actually handed.
  ///
  /// Called once per test and held in a local: `verify` marks the call verified, so a second
  /// reader in the same test finds nothing.
  String sentRate() =>
      verify(
        () => repository.create(
          ratePerUnit: captureAny(named: 'ratePerUnit'),
          costType: any(named: 'costType'),
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          notes: any(named: 'notes'),
          isActive: any(named: 'isActive'),
        ),
      ).captured.single as String;

  /// Both ids at once, in the order they are written below — a second `verify` in the same test
  /// would find a call the first already marked verified.
  ({int? productId, int? productVariantId}) sentIds() {
    final captured = verify(
      () => repository.create(
        productId: captureAny(named: 'productId'),
        productVariantId: captureAny(named: 'productVariantId'),
        costType: any(named: 'costType'),
        ratePerUnit: any(named: 'ratePerUnit'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    ).captured;

    return (productId: captured[0] as int?, productVariantId: captured[1] as int?);
  }

  /// Every answer the form can give, with defaults, so each test overrides only its own.
  Future<Either<Failure, ManufacturingCostRate>> submit({
    int? id,
    RateScope scope = RateScope.standard,
    int? scopeId,
    ManufacturingCostType costType = ManufacturingCostType.labor,
    String ratePerUnit = '3.5',
    String? notes,
    bool isActive = true,
  }) {
    return saveRate(
      id: id,
      scope: scope,
      scopeId: scopeId,
      costType: costType,
      ratePerUnit: ratePerUnit,
      notes: notes,
      isActive: isActive,
    );
  }

  group('the number', () {
    test('Arabic-Indic digits arrive as ASCII', () async {
      // Arrange & Act — ٣٫٥ is what the shop's own keyboard produces.
      await submit(ratePerUnit: '٣٫٥');

      // Assert
      expect(sentRate(), '3.5');
    });

    test('a comma is a decimal point', () async {
      // Arrange & Act
      await submit(ratePerUnit: '25,5');

      // Assert
      expect(sentRate(), '25.5');
    });

    test('the decimals typed are the decimals sent', () async {
      // Arrange — nothing rounds here: `numeric` accepts a decimal string, so the rate never has
      // to be round-tripped through a float to satisfy the rule.
      // Act
      await submit(ratePerUnit: ' 0.850 ');

      // Assert
      expect(sentRate(), '0.850');
    });
  });

  group('the rung', () {
    test('a rate pinned to a product carries no size', () async {
      // Act
      await submit(scope: RateScope.product, scopeId: 3);

      // Assert
      expect(sentIds(), (productId: 3, productVariantId: null));
    });

    test('a rate pinned to a size carries no product', () async {
      // Act
      await submit(scope: RateScope.variant, scopeId: 11);

      // Assert — the table refuses a row with both, and the two mean different rungs anyway.
      expect(sentIds(), (productId: null, productVariantId: 11));
    });

    test('the default rung sends neither, even when a product is still remembered', () async {
      // Arrange — the form keeps the product it was shown so that moving between the chips does
      // not lose the answer; only the chosen rung's id may travel.
      // Act
      await submit(scope: RateScope.standard, scopeId: 3);

      // Assert
      expect(sentIds(), (productId: null, productVariantId: null));
    });
  });

  group('the rest of the form', () {
    test('an empty note is sent as nothing, not as an empty string', () async {
      // Arrange & Act
      await submit(notes: '   ');

      // Assert
      verify(
        () => repository.create(
          notes: null,
          costType: any(named: 'costType'),
          ratePerUnit: any(named: 'ratePerUnit'),
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          isActive: any(named: 'isActive'),
        ),
      ).called(1);
    });

    test('an id corrects that rate rather than adding another', () async {
      // Act
      await submit(id: 7, scope: RateScope.product, scopeId: 3);

      // Assert
      verify(
        () => repository.update(
          7,
          costType: any(named: 'costType'),
          ratePerUnit: any(named: 'ratePerUnit'),
          productId: 3,
          productVariantId: null,
          notes: any(named: 'notes'),
          isActive: any(named: 'isActive'),
        ),
      ).called(1);
      verifyNever(
        () => repository.create(
          costType: any(named: 'costType'),
          ratePerUnit: any(named: 'ratePerUnit'),
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          notes: any(named: 'notes'),
          isActive: any(named: 'isActive'),
        ),
      );
    });

    test('the duplicate is the server\'s to refuse, in its own words', () async {
      // Arrange — one rate per kind per rung, and the 422 for it is keyed on `cost_type`.
      const failure = Failure.server(
        message: 'يوجد بالفعل معدل لهذا المنتج ولهذا النوع من التكاليف',
        statusCode: 422,
        fieldErrors: {
          'cost_type': ['يوجد بالفعل معدل لهذا المنتج ولهذا النوع من التكاليف'],
        },
      );
      when(
        () => repository.create(
          costType: any(named: 'costType'),
          ratePerUnit: any(named: 'ratePerUnit'),
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          notes: any(named: 'notes'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await submit(scope: RateScope.product, scopeId: 3);

      // Assert — the app never invents its own sentence for a rule the server owns.
      expect(
        result.fold((failure) => failure.message, (_) => null),
        'يوجد بالفعل معدل لهذا المنتج ولهذا النوع من التكاليف',
      );
    });
  });
}
