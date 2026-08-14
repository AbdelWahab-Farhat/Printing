import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_price_quote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The price under the quantity box, as it is typed.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late LineQuoteCubit cubit;

  const quote = PriceQuote(
    quantity: '300.000',
    unit: 'piece',
    unitLabel: 'قطعة',
    unitPrice: '1.100',
    total: '330.000',
    appliedTierMinQuantity: '100.000',
  );

  const belowMinimum = Failure.server(
    message: 'أقل كمية لهذا المنتج هي ١٠٠ قطعة',
    statusCode: 422,
  );

  void answerWith(Either<Failure, PriceQuote> answer) {
    when(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer((_) async => answer);
  }

  setUp(() {
    repository = _MockProductRepository();
    cubit = LineQuoteCubit(getPriceQuote: GetPriceQuote(repository));
    answerWith(const Right(quote));
  });

  tearDown(() => cubit.close());

  blocTest<LineQuoteCubit, LineQuoteState>(
    'a quantity asks the catalogue, and the price it answers is shown',
    build: () => cubit,
    // Act
    act: (cubit) => cubit.quote(productId: 7, variantId: 12, quantity: '300'),
    // Assert
    expect: () => const [LineQuoteState.loading(), LineQuoteState.priced(quote)],
  );

  blocTest<LineQuoteCubit, LineQuoteState>(
    'the quantity is normalised before it is asked about',
    build: () => cubit,
    // Act — ٣٠٠ from a Libyan keyboard, on the field that re-prices on every keystroke.
    act: (cubit) => cubit.quote(productId: 7, variantId: 12, quantity: '٣٠٠'),
    // Assert
    verify: (_) {
      verify(
        () => repository.quote(productId: 7, variantId: 12, quantity: '300'),
      ).called(1);
    },
  );

  blocTest<LineQuoteCubit, LineQuoteState>(
    'an empty quantity asks nothing and shows nothing',
    build: () => cubit,
    // Act — every keystroke arrives here, including the one that clears the box.
    act: (cubit) => cubit.quote(productId: 7, variantId: 12, quantity: '  '),
    // Assert
    expect: () => const [LineQuoteState.idle()],
    verify: (_) => verifyNever(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: any(named: 'quantity'),
      ),
    ),
  );

  blocTest<LineQuoteCubit, LineQuoteState>(
    'a refusal is shown as the sentence the server sent',
    setUp: () {
      // Arrange
      answerWith(const Left(belowMinimum));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.quote(productId: 7, variantId: 12, quantity: '50'),
    // Assert — «أقل كمية…» is a useful thing to read under the box, and the app has no business
    // rewriting it into «تعذّر التسعير».
    expect: () => const [LineQuoteState.loading(), LineQuoteState.failure(belowMinimum)],
  );

  blocTest<LineQuoteCubit, LineQuoteState>(
    'a product priced by hand is never asked about at all',
    build: () => cubit,
    // Act
    act: (cubit) => cubit.priceByHand(),
    // Assert — «حسب الطلب» has no answer to fetch; the clerk names the price.
    expect: () => const [LineQuoteState.byHand()],
    verify: (_) => verifyNever(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: any(named: 'quantity'),
      ),
    ),
  );

  blocTest<LineQuoteCubit, LineQuoteState>(
    'only the last answer is shown when two are in flight',
    setUp: () {
      // Arrange — typing 30 then 300 sends two requests, and the first may land second. Showing
      // the price of a quantity the box no longer holds is worse than showing none.
      var call = 0;
      when(
        () => repository.quote(
          productId: any(named: 'productId'),
          variantId: any(named: 'variantId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((invocation) async {
        final quantity = invocation.namedArguments[#quantity] as String;
        call++;
        // The first request answers late; the second is quick.
        await Future<void>.delayed(Duration(milliseconds: call == 1 ? 60 : 5));

        return Right(quote.copyWith(quantity: quantity, total: '$quantity.000'));
      });
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      unawaited(cubit.quote(productId: 7, variantId: 12, quantity: '30'));
      await cubit.quote(productId: 7, variantId: 12, quantity: '300');
    },
    wait: const Duration(milliseconds: 120),
    // Assert
    verify: (cubit) {
      expect(cubit.state, isA<LineQuotePriced>());
      expect((cubit.state as LineQuotePriced).quote.quantity, '300');
    },
  );
}
