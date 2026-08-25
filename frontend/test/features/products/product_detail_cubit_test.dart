import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One product, fetched fresh. The repository is faked and nothing touches Dio.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late ProductDetailCubit cubit;

  const productId = 7;

  /// A bag filed under «كيس شحن», with its one size drawing on that material's 25*35 shelf.
  ///
  /// The material is on the fixture rather than left off it because it is the only thing this
  /// screen still says about stock: the unit moved onto «الصنف المخزني» along with the endpoint
  /// that used to set it, and what is left here is a *reading* of where the sizes are filed.
  const product = Product(
    id: productId,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'كيس شحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    stockItemGroupId: 3,
    stockItemGroup: ProductMaterial(
      id: 3,
      code: 'G3',
      name: 'كيس شحن',
      defaultUnit: 'piece',
      defaultUnitLabel: 'قطعة',
    ),
    pricingMode: 'listed',
    pricingModeLabel: 'سعر معلن',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
    variants: [
      ProductVariant(
        id: 12,
        label: '25*35',
        widthCm: 25,
        heightCm: 35,
        stockItemId: 4,
        stockItem: VariantStockItem(
          id: 4,
          code: 'S4',
          name: 'كيس شحن',
          widthCm: 25,
          heightCm: 35,
          displayName: 'كيس شحن 25*35',
          unit: 'piece',
          unitLabel: 'قطعة',
        ),
      ),
    ],
  );

  setUp(() {
    repository = _MockProductRepository();
    cubit = ProductDetailCubit(
      productId: productId,
      getProduct: GetProduct(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<ProductDetailCubit, ProductDetailState>(
    'goes loading then loaded, and asks for the product it was built for',
    setUp: () {
      when(() => repository.product(any())).thenAnswer((_) async => const Right(product));
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailState.loading(),
      const ProductDetailState.loaded(product),
    ],
    verify: (_) {
      // The id is a construction argument, so there is no way for this Cubit to fetch a
      // different product than the screen is titled after.
      verify(() => repository.product(productId)).called(1);
    },
  );

  blocTest<ProductDetailCubit, ProductDetailState>(
    "surfaces the server's own message rather than a generic one",
    setUp: () {
      when(() => repository.product(any())).thenAnswer(
        (_) async => const Left(Failure.server(message: 'العنصر المطلوب غير موجود')),
      );
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailState.loading(),
      const ProductDetailState.failure(Failure.server(message: 'العنصر المطلوب غير موجود')),
    ],
  );

  blocTest<ProductDetailCubit, ProductDetailState>(
    'a refresh brings the change through without blanking what is on screen',
    setUp: () {
      // Renamed between the two reads, so the assertion is about the *sequence* and not merely
      // about a state that happens to be equal to the one before it.
      final answers = <Either<Failure, Product>>[
        const Right(product),
        const Right(Product(
          id: productId,
          code: 'P7',
          slug: 'shipping-bag',
          name: 'كيس شحن كبير',
          pricingUnit: 'piece',
          pricingUnitLabel: 'قطعة',
          pricingMode: 'listed',
          pricingModeLabel: 'سعر معلن',
          hasListedPrices: true,
          minOrderQuantity: '100.000',
        )),
      ];

      when(() => repository.product(any())).thenAnswer((_) async => answers.removeAt(0));
    },
    build: () => cubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    skip: 2, // the first load's loading + loaded
    expect: () => [
      // The new name, and **no `loading` before it**: a price list somebody has scrolled
      // halfway down must not jump back to a spinner because they pulled to refresh.
      isA<ProductDetailLoaded>().having((s) => s.product.name, 'name', 'كيس شحن كبير'),
    ],
  );

  // ─────────────────────── what this screen no longer does ───────────────────────

  test('reads the material the product is filed under, and never a unit of its own', () async {
    // Arrange — the one write this Cubit used to carry is gone with its endpoint: two products
    // at one size share one pile, so «كم يُعدّ به هذا الكيس» cannot be a product's answer. What
    // is left is a reading.
    when(() => repository.product(any())).thenAnswer((_) async => const Right(product));

    // Act
    await cubit.load();

    // Assert — the material's name and the shelf a size draws on both come off the product the
    // server sent. `shelfLabel` is `display_name` as composed server-side: an order refused at
    // «جاهزة» quotes that exact string, and a second spelling of it built here would be a second
    // thing for somebody to reconcile.
    final shown = cubit.state.product!;
    expect(shown.hasMaterial, isTrue);
    expect(shown.stockItemGroup?.name, 'كيس شحن');
    expect(shown.variants.single.shelfLabel, 'كيس شحن 25*35');
    expect(shown.unlinkedVariants, isEmpty);
  });

  test('a product that arrives after the screen is gone is not emitted', () async {
    // Arrange — the screen may be popped while the request is in flight, and emitting into a
    // closed Cubit throws.
    when(() => repository.product(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));

      return const Right(product);
    });

    // Act
    final inFlight = cubit.load();
    await cubit.close();
    await inFlight;

    // Assert — it never left `loading`, and nothing threw.
    expect(cubit.state, const ProductDetailState.loading());
  });
}
