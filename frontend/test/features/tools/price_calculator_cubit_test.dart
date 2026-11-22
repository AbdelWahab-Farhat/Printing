import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_price_quote.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/price_calculator_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// حاسبة الأسعار: lines priced by the catalogue as they are typed, and nothing written.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late PriceCalculatorCubit cubit;

  const small = ProductVariant(id: 11, label: '25*35');
  const large = ProductVariant(id: 12, label: '35*40');

  const shipping = Product(
    id: 1,
    code: 'P1',
    slug: 'shipping',
    name: 'أكياس الشحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'أسعار مدرجة',
    hasListedPrices: true,
    minOrderQuantity: '1.000',
    variants: [small, large],
  );

  const byRequest = Product(
    id: 2,
    code: 'P2',
    slug: '3d',
    name: 'أكياس ورقية 3D',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'quote_on_request',
    pricingModeLabel: 'حسب الطلب',
    minOrderQuantity: '1.000',
    variants: [ProductVariant(id: 21, label: 'حسب الطلب')],
  );

  PriceQuote quoteFor(String quantity, String total) => PriceQuote(
    quantity: quantity,
    unit: 'piece',
    unitLabel: 'قطعة',
    unitPrice: '0.950',
    total: total,
    appliedTierMinQuantity: '300.000',
  );

  void answer(String quantity, Either<Failure, PriceQuote> result, {Duration? after}) {
    when(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: quantity,
      ),
    ).thenAnswer((_) async {
      if (after != null) await Future<void>.delayed(after);
      return result;
    });
  }

  /// Long enough for the zero-length debounce timer and the fake repository to answer.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    repository = _MockProductRepository();
    cubit = PriceCalculatorCubit(getPriceQuote: GetPriceQuote(repository), debounce: Duration.zero);
  });

  tearDown(() => cubit.close());

  test('a typed quantity is priced by the catalogue, and the total and message follow', () async {
    // Arrange
    answer('500', Right(quoteFor('500.000', '475.000')));
    final key = cubit.add(shipping, small);

    // Act
    cubit.setQuantity(key, '500');
    await settle();

    // Assert
    final line = cubit.state.lineOf(key)!;
    expect(line.quote, LineQuoteState.priced(quoteFor('500.000', '475.000')));
    expect(cubit.state.isComplete, isTrue);
    expect(cubit.state.total, '475.000');
    expect(cubit.state.message, contains('• مقاس 25*35 — 500 قطعة × 0.95 = 475 د.ل'));
  });

  test('the server\'s refusal is kept on the line, and nothing is totalled', () async {
    // Arrange
    const refusal = Failure.server(message: 'أقل كمية لهذا المنتج هي ١٠٠ قطعة', statusCode: 422);
    answer('5', const Left(refusal));
    final key = cubit.add(shipping, small);

    // Act
    cubit.setQuantity(key, '5');
    await settle();

    // Assert
    expect(cubit.state.lineOf(key)!.quote, const LineQuoteState.failure(refusal));
    expect(cubit.state.isComplete, isFalse);
    expect(cubit.state.total, isNull);
  });

  test('a slow answer for an older quantity never overwrites the newer one', () async {
    // Arrange — «30» answers after «300» does.
    answer('30', Right(quoteFor('30.000', '33.000')), after: const Duration(milliseconds: 40));
    answer('300', Right(quoteFor('300.000', '285.000')));
    final key = cubit.add(shipping, small);

    // Act
    cubit.setQuantity(key, '30');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    cubit.setQuantity(key, '300');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    // Assert
    expect(cubit.state.lineOf(key)!.quote.quote?.total, '285.000');
  });

  test('emptying the box puts the line back to waiting, without asking', () async {
    // Arrange
    answer('500', Right(quoteFor('500.000', '475.000')));
    final key = cubit.add(shipping, small);
    cubit.setQuantity(key, '500');
    await settle();

    // Act
    cubit.setQuantity(key, '');
    await settle();

    // Assert
    expect(cubit.state.lineOf(key)!.quote, const LineQuoteState.idle());
    verify(() => repository.quote(productId: 1, variantId: 11, quantity: '500')).called(1);
  });

  test('a product priced «حسب الطلب» never asks, and counts once it has a quantity', () async {
    // Arrange
    final key = cubit.add(byRequest, byRequest.variants.first);

    // Act
    cubit.setQuantity(key, '200');
    await settle();

    // Assert
    expect(cubit.state.lineOf(key)!.quote, const LineQuoteState.byHand());
    expect(cubit.state.isComplete, isTrue);
    expect(cubit.state.message, contains('السعر حسب الطلب'));
    verifyNever(
      () => repository.quote(
        productId: any(named: 'productId'),
        variantId: any(named: 'variantId'),
        quantity: any(named: 'quantity'),
      ),
    );
  });

  test('a hand price on a «حسب الطلب» line joins the total; an invalid one does not', () async {
    // Arrange
    answer('500', Right(quoteFor('500.000', '475.000')));
    final priced = cubit.add(shipping, small);
    final byHand = cubit.add(byRequest, byRequest.variants.first);
    cubit
      ..setQuantity(priced, '500')
      ..setQuantity(byHand, '200');
    await settle();

    // Act
    cubit.setUnitPrice(byHand, '١٫٥'.replaceAll('٫', '.'));

    // Assert
    expect(cubit.state.lineOf(byHand)!.handUnitPrice, '1.5');
    expect(cubit.state.total, '775.000');
    expect(cubit.state.message, contains('200 قطعة × 1.5 = 300 د.ل'));

    // Act — something that is not a price.
    cubit.setUnitPrice(byHand, '1.2.3');

    // Assert
    expect(cubit.state.lineOf(byHand)!.hasInvalidUnitPrice, isTrue);
    expect(cubit.state.total, '475.000');
  });

  test('a catalogue-priced line ignores a hand price', () {
    // Arrange
    final key = cubit.add(shipping, small);

    // Act
    cubit.setUnitPrice(key, '9');

    // Assert
    expect(cubit.state.lineOf(key)!.unitPrice, '');
  });

  test(
    'a line moves to a free size and is re-priced, but never onto a size already listed',
    () async {
      // Arrange
      answer('500', Right(quoteFor('500.000', '475.000')));
      final first = cubit.add(shipping, small);
      cubit.setQuantity(first, '500');
      await settle();

      // Act — onto the free size.
      cubit.changeVariant(first, large);
      await settle();

      // Assert
      expect(cubit.state.lineOf(first)!.variant, large);
      verify(() => repository.quote(productId: 1, variantId: 12, quantity: '500')).called(1);

      // Arrange — a second line now holds the small size.
      final second = cubit.add(shipping, small);

      // Act — trying to move the first line onto it.
      cubit.changeVariant(first, small);

      // Assert
      expect(cubit.state.lineOf(first)!.variant, large);
      expect(cubit.state.lineOf(second)!.variant, small);
    },
  );

  test('removing a line drops it and any answer still on its way', () async {
    // Arrange
    answer('500', Right(quoteFor('500.000', '475.000')), after: const Duration(milliseconds: 30));
    final key = cubit.add(shipping, small);
    cubit.setQuantity(key, '500');
    await Future<void>.delayed(const Duration(milliseconds: 5));

    // Act
    cubit.remove(key);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    // Assert
    expect(cubit.state.lines, isEmpty);
  });

  test('clear empties the calculator', () {
    // Arrange
    cubit
      ..add(shipping, small)
      ..add(byRequest, byRequest.variants.first);

    // Act
    cubit.clear();

    // Assert
    expect(cubit.state.isEmpty, isTrue);
  });

  test('the total waits until every line is ready', () async {
    // Arrange
    answer('500', Right(quoteFor('500.000', '475.000')));
    final priced = cubit.add(shipping, small);
    cubit.add(shipping, large);

    // Act
    cubit.setQuantity(priced, '500');
    await settle();

    // Assert — the second line has no quantity yet.
    expect(cubit.state.isComplete, isFalse);
    expect(cubit.state.total, isNull);
  });
}
