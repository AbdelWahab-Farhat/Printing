import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/usecases/get_product.dart';

/// One product, fetched fresh. The repository is faked and nothing touches Dio.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late ProductDetailCubit cubit;

  const productId = 7;

  const product = Product(
    id: productId,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'كيس شحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'listed',
    pricingModeLabel: 'سعر معلن',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
  );

  setUp(() {
    repository = _MockProductRepository();
    cubit = ProductDetailCubit(productId: productId, getProduct: GetProduct(repository));
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
