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

  // ── صفحة المنتج الجديدة: زرّا + و− على طرفي السلايدر، والسلايدر نفسه، وبطاقات الأسعار ──

  /// منتجٌ يُباع بالقطعة من ١٠٠ — خطوته ٥٠، وسلايدره من ١٠٠ إلى ٢٬٠٠٠.
  const printed = Product(
    id: 7,
    name: 'أكياس شحن - مطبوعة',
    pricingUnit: 'piece',
    minOrderQuantity: '100.000',
    variants: [ProductVariant(id: 20, label: 'متوسط')],
  );

  /// منتجٌ يُباع بالكيلو من ١ — خطوته ١.
  const plain = Product(
    id: 12,
    name: 'أكياس شفافه - ساده',
    pricingUnit: 'kilogram',
    minOrderQuantity: '1.000',
    variants: [ProductVariant(id: 40, label: 'صغير جدا')],
  );

  ProductDetailState printedAt(String quantity, {PriceQuote? quote}) =>
      ProductDetailState.loaded(
        product: printed,
        selectedVariantId: 20,
        quantity: quantity,
        quote: quote,
      );

  group('stepping', () {
    blocTest<ProductDetailCubit, ProductDetailState>(
      '+ moves up one step and asks the server for the new quantity',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500'),
      act: (cubit) => cubit.increase(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) {
        expect((cubit.state as ProductDetailLoaded).quantity, '550');
        verify(
          () => repository.quote(productId: 7, variantId: 20, quantity: '550'),
        ).called(1);
      },
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      '+ from between two steps lands on the next step, not a step beyond it',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('437'),
      act: (cubit) => cubit.increase(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '450'),
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      '− moves down one step',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500'),
      act: (cubit) => cubit.decrease(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '450'),
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      '− from between two steps lands on the step below',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('437'),
      act: (cubit) => cubit.decrease(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '400'),
    );

    /// الحدّ الأدنى هو ما يرفض الخادم ما دونه، فلا يعبره الزر ولا يكلّف طلباً يعرف جوابه.
    blocTest<ProductDetailCubit, ProductDetailState>(
      '− stops at the minimum and asks nothing',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('100.000'),
      act: (cubit) => cubit.decrease(),
      wait: const Duration(milliseconds: 30),
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

    blocTest<ProductDetailCubit, ProductDetailState>(
      '+ on an empty field starts at the minimum',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt(''),
      act: (cubit) => cubit.increase(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '100'),
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      'a kilogram steps by one, and a fraction steps onto the whole kilogram beside it',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => const ProductDetailState.loaded(
        product: plain,
        selectedVariantId: 40,
        quantity: '2.5',
      ),
      act: (cubit) => cubit.increase(),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '3'),
    );
  });

  group('sliding', () {
    /// السحب يطلق عشرات القيم في الثانية. تُرسم الكمية مع الإصبع، والسعر يُطلب مرةً واحدة حين
    /// يُرفع الإصبع — وحتى ذلك الحين يبقى السعر السابق ظاهراً ومعلَّماً بأنه يتجدّد.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'the thumb snaps to a step and nothing is asked until it is let go',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500', quote: quote),
      act: (cubit) => cubit.slide(537),
      expect: () => [
        const ProductDetailState.loaded(
          product: printed,
          selectedVariantId: 20,
          quantity: '550',
          quote: quote,
          isQuoting: true,
        ),
      ],
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

    blocTest<ProductDetailCubit, ProductDetailState>(
      'the thumb cannot take the quantity past either end',
      build: build,
      seed: () => printedAt('500'),
      act: (cubit) => cubit
        ..slide(20)
        ..slide(99999),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '2000'),
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      'letting go asks once, for where the thumb stopped',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500'),
      act: (cubit) async {
        cubit
          ..slide(620)
          ..slide(690)
          ..slide(700);
        await cubit.refreshQuote();
      },
      verify: (_) {
        verify(
          () => repository.quote(productId: 7, variantId: 20, quantity: '700'),
        ).called(1);
        verifyNoMoreInteractions(repository);
      },
    );

    /// جوابٌ كان في الطريق حين تحرّك الإبهام جوابٌ عن كميةٍ لم تعد على الشاشة.
    test('an answer still on its way when the thumb moves is dropped', () async {
      // Arrange
      when(
        () => repository.quote(
          productId: any(named: 'productId'),
          variantId: any(named: 'variantId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));

        return const Right(cheaper);
      });
      final cubit = build()..emit(printedAt('500', quote: quote));

      // Act
      final slow = cubit.refreshQuote();
      cubit.slide(800);
      await slow;
      final settled = cubit.state as ProductDetailLoaded;

      // Assert
      expect(settled.quantity, '800');
      expect(settled.quote, quote);
      expect(settled.isQuoting, isTrue);
      await cubit.close();
    });
  });

  group('the price breaks', () {
    blocTest<ProductDetailCubit, ProductDetailState>(
      'choosing a break orders exactly its threshold',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500'),
      act: (cubit) => cubit.chooseTier(
        const PriceTier(id: 3, minQuantity: '1000.000', unitPrice: '1.160'),
      ),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) {
        expect((cubit.state as ProductDetailLoaded).quantity, '1000');
        verify(
          () => repository.quote(productId: 7, variantId: 20, quantity: '1000'),
        ).called(1);
      },
    );

    /// كسرٌ يبدأ من ١ على منتجٍ لا يُطلب منه أقل من ١٠٠ — ما يُطلب فعلاً هو ١٠٠.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'a break below the product minimum orders the minimum',
      build: () {
        stubQuote();

        return build();
      },
      seed: () => printedAt('500'),
      act: (cubit) => cubit.chooseTier(
        const PriceTier(id: 1, minQuantity: '1.000', unitPrice: '1.720'),
      ),
      wait: const Duration(milliseconds: 30),
      verify: (cubit) => expect((cubit.state as ProductDetailLoaded).quantity, '100'),
    );
  });

  group('while a new price is on its way', () {
    /// الرقم الذي يختفي مع كل لمسة يُقرأ سعراً انكسر. يبقى السابق، والشاشة تخفّته.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'the last price stays on screen, marked as being refreshed',
      build: () {
        stubQuote(cheaper);

        return build();
      },
      seed: () => printedAt('500', quote: quote),
      act: (cubit) => cubit.setQuantity('600'),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        printedAt('600', quote: quote),
        const ProductDetailState.loaded(
          product: printed,
          selectedVariantId: 20,
          quantity: '600',
          quote: quote,
          isQuoting: true,
        ),
        printedAt('600', quote: cheaper),
      ],
    );

    /// إجماليٌّ لكميةٍ أخرى بجانب رسالة الرفض أسوأ من لا إجمالي.
    blocTest<ProductDetailCubit, ProductDetailState>(
      'a refusal clears the old price rather than leaving it beside the new quantity',
      build: () {
        when(
          () => repository.quote(
            productId: any(named: 'productId'),
            variantId: any(named: 'variantId'),
            quantity: any(named: 'quantity'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'أقل كمية ١٠٠ قطعة')),
        );

        return build();
      },
      seed: () => printedAt('50', quote: quote),
      act: (cubit) => cubit.refreshQuote(),
      skip: 1,
      expect: () => const [
        ProductDetailState.loaded(
          product: printed,
          selectedVariantId: 20,
          quantity: '50',
          quoteFailure: ServerFailure(message: 'أقل كمية ١٠٠ قطعة'),
        ),
      ],
    );
  });

  group('canDecrease', () {
    test('is false at the minimum', () {
      // Arrange
      final state = printedAt('100.000');

      // Act
      final canDecrease = state.canDecrease;

      // Assert
      expect(canDecrease, isFalse);
    });

    test('is true above it', () {
      // Arrange
      final state = printedAt('150');

      // Act
      final canDecrease = state.canDecrease;

      // Assert
      expect(canDecrease, isTrue);
    });
  });

  test('a typed quantity beyond the slider sits the thumb at the end', () {
    // Arrange
    final state = printedAt('5000');

    // Act
    final onSlider = state.quantityOnSlider;

    // Assert
    expect(onSlider, 2000);
  });

  group('hasOrderableQuantity', () {
    /// The state as the screen holds it, with [quantity] in the field.
    ProductDetailState withQuantity(String quantity) =>
        ProductDetailState.loaded(product: bag, selectedVariantId: 11, quantity: quantity);

    test('a lone dot is not a quantity', () {
      // The one this exists for: it used to reach the basket and be refused at the till, because
      // `is_numeric('.')` is false on the server too.
      expect(withQuantity('.').hasOrderableQuantity, isFalse);
    });

    test('a trailing dot is left alone — it is the road to 100.5', () {
      // And harmless where a lone dot is not: the server reads «100.» as 100.
      expect(withQuantity('100.').hasOrderableQuantity, isTrue);
    });

    test('nothing, and nonsense, are refused', () {
      expect(withQuantity('').hasOrderableQuantity, isFalse);
      expect(withQuantity('1.2.3').hasOrderableQuantity, isFalse);
    });

    test('zero is not an order', () {
      expect(withQuantity('0').hasOrderableQuantity, isFalse);
      expect(withQuantity('0.0').hasOrderableQuantity, isFalse);
    });

    test('ordinary quantities pass, whole and fractional', () {
      expect(withQuantity('1000').hasOrderableQuantity, isTrue);
      expect(withQuantity('7.5').hasOrderableQuantity, isTrue);
    });

    test('a screen with no product answers no', () {
      // `loading` has no quantity to read; the getter must not assume it is on `loaded`.
      expect(const ProductDetailState.loading().hasOrderableQuantity, isFalse);
    });
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
