import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/set_product_stock_unit.dart';
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

  setUpAll(() {
    // `any()` on an enum parameter still needs a fallback: mocktail builds the matcher before it
    // ever sees a real argument.
    registerFallbackValue(PricingUnit.piece);
  });

  const product = Product(
    id: productId,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'كيس شحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    stockUnit: 'piece',
    stockUnitLabel: 'قطعة',
    pricingMode: 'listed',
    pricingModeLabel: 'سعر معلن',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
  );

  /// The same bag after somebody declared the shelf counts it by the kilo.
  const stockedByWeight = Product(
    id: productId,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'كيس شحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    stockUnit: 'kilogram',
    stockUnitLabel: 'كيلوغرام',
    pricingMode: 'listed',
    pricingModeLabel: 'سعر معلن',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
  );

  setUp(() {
    repository = _MockProductRepository();
    cubit = ProductDetailCubit(
      productId: productId,
      getProduct: GetProduct(repository),
      setStockUnit: SetProductStockUnit(repository),
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
          stockUnit: 'piece',
          stockUnitLabel: 'قطعة',
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

  // ─────────────────────── declaring the stock unit ───────────────────────

  test('the refreshed product the endpoint answers with is what the screen shows', () async {
    // Arrange — the server cascades the change to every warehouse balance and cost batch in one
    // transaction and hands back the whole product, so there is nothing left to re-read.
    when(() => repository.product(any())).thenAnswer((_) async => const Right(product));
    when(
      () => repository.setStockUnit(any(), any()),
    ).thenAnswer((_) async => const Right(stockedByWeight));
    await cubit.load();

    // Act
    final failure = await cubit.setStockUnit(PricingUnit.kilogram);

    // Assert — one request, not two: no follow-up GET, and the unit on screen is the one the
    // server confirmed rather than the one the user tapped.
    expect(failure, isNull);
    expect(cubit.state.product?.stockUnit, 'kilogram');
    verify(() => repository.setStockUnit(productId, PricingUnit.kilogram)).called(1);
    verify(() => repository.product(productId)).called(1);
  });

  test('a refusal leaves the product exactly as it was, and says why', () async {
    // Arrange — `inventory.manage`, not `products.manage`: somebody who may edit the catalogue
    // is not therefore allowed to redeclare what the shelves count in.
    when(() => repository.product(any())).thenAnswer((_) async => const Right(product));
    when(() => repository.setStockUnit(any(), any())).thenAnswer(
      (_) async => const Left(Failure.server(message: 'ليست لديك صلاحية لهذا الإجراء')),
    );
    await cubit.load();

    // Act
    final failure = await cubit.setStockUnit(PricingUnit.kilogram);

    // Assert — the message is handed back for the screen to show, and the state is untouched:
    // a failed correction must not blank a product somebody is reading.
    expect(failure?.message, 'ليست لديك صلاحية لهذا الإجراء');
    expect(cubit.state.product, product);
  });

  test('a change that lands after the screen is gone is not emitted', () async {
    // Arrange
    when(() => repository.product(any())).thenAnswer((_) async => const Right(product));
    when(() => repository.setStockUnit(any(), any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));

      return const Right(stockedByWeight);
    });
    await cubit.load();

    // Act
    final inFlight = cubit.setStockUnit(PricingUnit.kilogram);
    await cubit.close();
    await inFlight;

    // Assert — emitting into a closed Cubit throws, and nothing did.
    expect(cubit.state.product, product);
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
