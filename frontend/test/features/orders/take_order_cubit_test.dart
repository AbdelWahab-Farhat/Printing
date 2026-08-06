import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/new_order.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/viewmodel/take_order_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/take_order.dart';

/// The new-order screen's ViewModel.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeNewOrder extends Fake implements NewOrder {}

void main() {
  late _MockOrderRepository repository;
  late TakeOrderCubit cubit;

  setUpAll(() => registerFallbackValue(_FakeNewOrder()));

  const stored = Order(
    id: 52,
    code: '52',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 3,
    cityId: 1,
    designSource: 'none',
    designSourceLabel: 'بدون تصميم',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
  );

  const refusal = Failure.server(
    message: 'العميل «محل النور» معطَّل، ولا تُؤخذ منه طلبيات',
    statusCode: 422,
  );

  setUp(() {
    repository = _MockOrderRepository();
    cubit = TakeOrderCubit(takeOrder: TakeOrder(repository), customerId: 3);
  });

  tearDown(() => cubit.close());

  Future<void> submit(TakeOrderCubit cubit) => cubit.submit(
    cityId: 1,
    lines: const [DraftOrderLine(productId: 7, productVariantId: 12, quantity: '300')],
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'goes submitting then success, carrying the order the server stored',
    setUp: () {
      // Arrange
      when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    },
    build: () => cubit,
    // Act
    act: submit,
    // Assert
    expect: () => const [TakeOrderState.submitting(), TakeOrderState.success(stored)],
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'the customer comes from the screen the form was opened inside, never from the caller',
    setUp: () {
      // Arrange
      when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    },
    build: () => cubit,
    // Act
    act: submit,
    // Assert — the whole reason «طلبية جديدة» lives on a customer's screen.
    verify: (_) {
      final sent = verify(() => repository.create(captureAny())).captured.single as NewOrder;
      expect(sent.customerId, 3);
    },
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'a refusal is shown with the server’s own words, and the form stays open',
    setUp: () {
      // Arrange
      when(() => repository.create(any())).thenAnswer((_) async => const Left(refusal));
    },
    build: () => cubit,
    // Act
    act: submit,
    // Assert — a failed submit leaves everything the clerk typed where it is; the screen owns
    // the draft, and this state says nothing that would clear it.
    expect: () => const [TakeOrderState.submitting(), TakeOrderState.failure(refusal)],
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'a second tap while the first is in flight is ignored',
    setUp: () {
      // Arrange — an order has no natural key, so two POSTs are two orders with two numbers,
      // and the second has to be cancelled by hand.
      when(() => repository.create(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));

        return const Right(stored);
      });
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      unawaited(submit(cubit));
      await submit(cubit);
    },
    wait: const Duration(milliseconds: 50),
    // Assert
    verify: (_) => verify(() => repository.create(any())).called(1),
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'an order with no lines is never sent',
    setUp: () {
      // Arrange
      when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    },
    build: () => cubit,
    // Act — the button is disabled without a line; this is the half that is a rule.
    act: (cubit) => cubit.submit(cityId: 1, lines: const []),
    // Assert — no request, and no state change to explain one.
    expect: () => const <TakeOrderState>[],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<TakeOrderCubit, TakeOrderState>(
    'correcting a field clears the previous refusal',
    setUp: () {
      // Arrange
      when(() => repository.create(any())).thenAnswer((_) async => const Left(refusal));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await submit(cubit);
      cubit.clearFailure();
    },
    // Assert — an error under a field disappears as it is corrected rather than lingering
    // until the next submit.
    expect: () => const [
      TakeOrderState.submitting(),
      TakeOrderState.failure(refusal),
      TakeOrderState.initial(),
    ],
  );
}
