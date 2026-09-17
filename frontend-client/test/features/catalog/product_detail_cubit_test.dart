import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalogRepository repository;

  const small = ProductVariant(id: 10, label: '25*35');
  const large = ProductVariant(id: 11, label: '30*40');

  const bag = Product(
    id: 1,
    name: 'كيس شحن فلاير',
    minOrderQuantity: '500',
    variants: [small, large],
  );

  const quote = PriceQuote(quantity: '500', unitPrice: '0.950', total: '475.000');
  const cheaper = PriceQuote(quantity: '5000', unitPrice: '0.850', total: '4250.000');

  setUp(() => repository = _MockCatalogRepository());

  ProductDetailCubit build() => ProductDetailCubit(
    getProduct: GetProduct(repository),
    quote: QuotePrice(repository),
  );

  void stubQuote([PriceQuote answer = quote]) {
    when(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer((_) async => Right(answer));
  }

  group('load', () {
    /// The first size is chosen and the quantity starts at the product's own floor — the
    /// commonest correct answer, and it saves the customer discovering the minimum by being
    /// refused.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'selects the first size and opens at the minimum order quantity',
      build: () {
        when(() => repository.product(any())).thenAnswer((_) async => const Right(bag));
        stubQuote();

        return build();
      },
      act: (cubit) => cubit.load(1),
      skip: 1,
      expect: () => [
        const ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
        ),
        const ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
          isQuoting: true,
        ),
        const ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
          quote: quote,
        ),
      ],
    );
  });

  group('quoting', () {
    /// **Nothing in this app multiplies a unit price by a quantity.** Changing the quantity asks
    /// the server again, because the tier rules live there and a copy here would be the one that
    /// disagrees with the invoice.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'changing the quantity re-asks the server rather than recomputing',
      build: () {
        stubQuote(cheaper);

        return build();
      },
      seed: () => const ProductDetailState.loaded(
        product: bag,
        selectedVariantId: 10,
        quantity: '500',
        quote: quote,
      ),
      act: (cubit) => cubit.setQuantity('5000'),
      wait: const Duration(milliseconds: 30),
      verify: (_) {
        verify(
          () => repository.quote(productId: 1, variantId: 10, quantity: '5000'),
        ).called(1);
      },
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      'changing the size re-quotes too',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => const ProductDetailState.loaded(
        product: bag,
        selectedVariantId: 10,
        quantity: '500',
      ),
      act: (cubit) => cubit.selectVariant(11),
      wait: const Duration(milliseconds: 30),
      verify: (_) {
        verify(
          () => repository.quote(productId: 1, variantId: 11, quantity: '500'),
        ).called(1);
      },
    );

    /// **The race a stepper creates.** Tapping + three times fires three quotes; a slow answer to
    /// the first must not overwrite the answer to the third, or the total flickers back to a
    /// number nobody asked for.
    test('a stale quote is dropped rather than shown', () async {
      when(() => repository.product(any())).thenAnswer((_) async => const Right(bag));

      var call = 0;
      when(
        () => repository.quote(
          productId: any(named: 'productId'),
          variantId: any(named: 'variantId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async {
        call++;
        // The first answer is the slow one — exactly the case that goes wrong.
        await Future<void>.delayed(Duration(milliseconds: call == 1 ? 60 : 5));

        return Right(call == 1 ? quote : cheaper);
      });

      final cubit = build();
      cubit.emit(
        const ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
        ),
      );

      final slow = cubit.refreshQuote();
      cubit.setQuantity('5000');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await slow;

      expect((cubit.state as ProductDetailLoaded).quote, cheaper);
      await cubit.close();
    });

    /// A failed quote leaves the product on screen — it is readable, and only the price is
    /// missing.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'a failed quote keeps the product and reports only the price',
      build: () {
        when(
          () => repository.quote(
            productId: any(named: 'productId'),
            variantId: any(named: 'variantId'),
            quantity: any(named: 'quantity'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      seed: () => const ProductDetailState.loaded(
        product: bag,
        selectedVariantId: 10,
        quantity: '500',
      ),
      act: (cubit) => cubit.refreshQuote(),
      expect: () => const [
        ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
          isQuoting: true,
        ),
        ProductDetailState.loaded(
          product: bag,
          selectedVariantId: 10,
          quantity: '500',
          quoteFailure: NetworkFailure(message: 'لا يوجد اتصال'),
        ),
      ],
    );

    /// A product sold on request has no tiers to quote against — the screen draws «اطلب عرض
    /// سعر» rather than a total, and must not spend a request finding that out.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'a quote-only product is never quoted',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => const ProductDetailState.loaded(
        product: Product(id: 2, name: 'حسب الطلب', hasListedPrices: false),
        selectedVariantId: 99,
      ),
      act: (cubit) => cubit.refreshQuote(),
      expect: () => const <ProductDetailState>[],
      verify: (_) {
        verifyNever(
          () => repository.quote(
            productId: any(named: 'productId'),
            variantId: any(named: 'variantId'),
            quantity: any(named: 'quantity'),
          ),
        );
      },
    );
  });

  test('selectedVariant resolves the chosen size from the product', () {
    const state = ProductDetailState.loaded(product: bag, selectedVariantId: 11);

    expect(state.selectedVariant, large);
  });

  test('lowestUnitPrice is the cheapest break across every size, as the server sent it', () {
    const priced = Product(
      id: 1,
      name: 'كيس',
      variants: [
        ProductVariant(
          id: 1,
          label: '25*35',
          priceTiers: [PriceTier(id: 1, minQuantity: '1000', unitPrice: '0.950')],
        ),
        ProductVariant(
          id: 2,
          label: '30*40',
          priceTiers: [PriceTier(id: 2, minQuantity: '5000', unitPrice: '0.850')],
        ),
      ],
    );

    expect(priced.lowestUnitPrice, '0.850');
  });
}
