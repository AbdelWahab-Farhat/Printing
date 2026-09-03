import 'package:dartz/dartz.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/save_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «سعر التكلفة» on its way from the form to the API.
///
/// **The fourteenth number on the form, and the one with the sharpest edge.** A cost typed as
/// `٢٥` on a Libyan keyboard is not-a-number to the server's `numeric` rule; and a size sent
/// without the key at all is saved with **no** cost, because `PUT /products/{id}` replaces the
/// whole variant set. So the use case normalises what was typed and passes an untouched value
/// straight through — and turns a blank box into an absent key rather than an empty string.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

class _FakeNewProduct extends Fake implements NewProduct {}

void main() {
  late _MockProductRepository repository;
  late SaveProduct saveProduct;

  const stored = Product(
    id: 3,
    code: 'P3',
    slug: 'business-cards',
    name: 'كروت بزنس',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'حسب الكمية',
    minOrderQuantity: '50.000',
  );

  setUpAll(() {
    registerFallbackValue(_FakeNewProduct());
    registerFallbackValue(
      const PickedFile(path: '/tmp/fallback.jpg', name: 'fallback.jpg', sizeBytes: 1),
    );
  });

  setUp(() {
    repository = _MockProductRepository();
    saveProduct = SaveProduct(repository);
    when(() => repository.update(any(), any())).thenAnswer((_) async => const Right(stored));
  });

  /// The draft the *update* endpoint was handed. One shot: `verify` marks the call verified.
  NewProduct updated() =>
      verify(() => repository.update(any(), captureAny())).captured.single as NewProduct;

  Future<void> submit(List<DraftVariant> variants) => saveProduct(
    id: 3,
    name: 'كروت بزنس',
    productCategoryId: 9,
    pricingUnit: 'piece',
    pricingMode: 'tiered',
    minOrderQuantity: '50',
    variants: variants,
  );

  test('a cost typed on a Libyan keyboard reaches the API as ASCII', () async {
    // Arrange - Act
    await submit(const [DraftVariant(label: 'قياسي', costPrice: '٢٥,٥')]);

    // Assert
    expect(updated().variants.single.costPrice, '25.5');
  });

  test('a cost the form was merely showing is sent back untouched', () async {
    // Arrange — the round trip: the row was seeded from `data.variants[].cost_price` and nobody
    // touched it. Dropping it here would wipe the cost on a save about something else.
    // Act
    await submit(const [
      DraftVariant(id: 12, label: 'قياسي', costPrice: '25.000'),
      DraftVariant(id: 13, label: 'مربع', costPrice: '30.000'),
    ]);

    // Assert
    final sizes = updated().variants;
    expect(sizes.map((size) => size.costPrice), ['25.000', '30.000']);
  });

  test('a blank box is an absent key, never an empty string', () async {
    // Arrange — the server reads `''` as «no cost», so the outcome is the same either way; but
    // an absent key is what the log shows for a size that never had one, and it is also what a
    // size under a printed heading *must* send or the whole save is refused.
    // Act
    await submit(const [
      DraftVariant(label: 'قياسي', costPrice: ''),
      DraftVariant(label: 'مربع'),
    ]);

    // Assert
    final sizes = updated().variants;
    expect(sizes.map((size) => size.costPrice), [null, null]);
    expect(sizes.first.toJson().containsKey('cost_price'), isFalse);
  });
}
