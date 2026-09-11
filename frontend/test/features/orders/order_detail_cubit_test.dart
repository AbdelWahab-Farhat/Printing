import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/stock_effect.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late OrderDetailCubit cubit;

  /// The server's preview, kept to its two required fields on purpose: what a delete would put
  /// back is the *server's* sentence, and a test that spelled out a list of goods would be
  /// asserting on a shape this file has no business pinning.
  const preview = StockEffect(
    stock: WarehouseEffect(
    kind: StockEffectKind.none,
    warning: 'لن يتحرّك أي مخزون بحذف هذه الطلبية.',
    ),
  );

  Order orderWith({
    OrderStatus status = OrderStatus.ready,
    String label = 'جاهزة',
    List<OrderTransition> transitions = const [],
    StockEffect? effect,
  }) {
    return Order(
      stockEffect: effect,
      id: 7,
      code: '7',
      status: status,
      statusLabel: label,
      isFinal: false,
      availableTransitions: transitions,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '330.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: '0.00',
      grandTotal: '350.00',
    );
  }

  setUpAll(() => registerFallbackValue(OrderStatus.printing));

  setUp(() {
    repository = _MockOrderRepository();
    cubit = OrderDetailCubit(
      orderId: 7,
      getOrder: GetOrder(repository),
      addDesign: AddOrderDesign(repository),
      reviewDesign: ReviewOrderDesign(repository),
      reinstateOrder: ReinstateOrder(repository),
      deleteOrder: DeleteOrder(repository),
      restoreOrder: RestoreOrder(repository),
      confirmReadyMessage: ConfirmReadyMessage(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── loading ─────────────────────────────

  blocTest<OrderDetailCubit, OrderDetailState>(
    'emits loading then loaded',
    build: () {
      // Arrange
      when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));

      return cubit;
    },
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<OrderDetailLoading>(),
      isA<OrderDetailLoaded>().having((s) => s.order.code, 'code', '7'),
    ],
  );

  blocTest<OrderDetailCubit, OrderDetailState>(
    "a failed load shows the server's own message",
    build: () {
      // Arrange
      when(() => repository.order(7)).thenAnswer(
        (_) async => const Left(Failure.server(message: 'الطلبية غير موجودة')),
      );

      return cubit;
    },
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<OrderDetailLoading>(),
      isA<OrderDetailFailure>().having(
        (s) => s.failure.message,
        'message',
        'الطلبية غير موجودة',
      ),
    ],
  );

  test('refreshing keeps the order on screen instead of blanking it', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();

    // Act — the pull-to-refresh handler is the same method.
    final future = cubit.load();

    // Assert — no loading state in between: blanking the screen on every pull makes the
    // gesture feel like leaving it.
    expect(cubit.state, isA<OrderDetailLoaded>());
    await future;
  });

  // ───────────────────────────── taking the move back ─────────────────────────────

  test('the order the move screen came back with replaces what is on screen', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();

    // Act — what `OrderStatusPage` popped with, which *is* the server's own answer.
    cubit.replace(orderWith(status: OrderStatus.printing, label: 'قيد الطباعة'));

    // Assert — no second read: the response to a move carries the new order whole, including
    // the different set of moves that now follow it.
    expect(cubit.state.order?.statusLabel, 'قيد الطباعة');
    expect(cubit.state, isA<OrderDetailLoaded>());
    verifyNever(() => repository.changeStatus(any(), status: any(named: 'status')));
  });

  // ───────────────────────────── the artwork conversation ─────────────────────────────

  test('versions are proposed one at a time, then the order is read again', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    when(
      () => repository.addDesign(7, customerDesignId: any(named: 'customerDesignId')),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final failure = await cubit.addDesigns([12, 13]);

    // Assert — one at a time because the server allocates the version number, and «النسخة
    // الثالثة» has to mean the file the conversation called the third.
    expect(failure, isNull);
    verify(() => repository.addDesign(7, customerDesignId: 12)).called(1);
    verify(() => repository.addDesign(7, customerDesignId: 13)).called(1);
    verify(() => repository.order(7)).called(2);
  });

  test('a refused version stops the ones behind it and is handed back', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    when(
      () => repository.addDesign(7, customerDesignId: 12),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'هذا التصميم لا يخص هذا العميل')),
    );

    // Act
    final failure = await cubit.addDesigns([12, 13]);

    // Assert — the screen shows the sentence; the second file is not sent into the same wall.
    expect(failure?.message, 'هذا التصميم لا يخص هذا العميل');
    verifyNever(() => repository.addDesign(7, customerDesignId: 13));
  });

  // ───────────────────────────── الأرشيف: one tap, one request ─────────────────────────────

  test('a second «حذف» while the first is still on the wire sends nothing', () async {
    // Arrange — the delete is held open, so the second call lands while the first is out. Two
    // taps on a floating button a few milliseconds apart is the ordinary way this happens.
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    final held = Completer<Either<Failure, Order>>();
    when(() => repository.deleteOrder(7)).thenAnswer((_) => held.future);

    // Act
    final first = cubit.archive();
    final second = cubit.archive();
    held.complete(Right(orderWith()));
    await Future.wait([first, second]);

    // Assert — `isWorking` has to be read *before* the usecase is called: an argument evaluated
    // at the call site is already on the wire by the time the guard inside runs, and the second
    // response is then thrown away while the screen reports success.
    verify(() => repository.deleteOrder(7)).called(1);
    expect(await second, isNull);
  });

  test('a second «استعادة» while the first is still on the wire sends nothing', () async {
    // Arrange — the same shape, and it matters more here: a restore draws stock off the shelf,
    // so a second one is a second deduction.
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    final held = Completer<Either<Failure, Order>>();
    when(() => repository.restoreOrder(7)).thenAnswer((_) => held.future);

    // Act
    final first = cubit.restore();
    final second = cubit.restore();
    held.complete(Right(orderWith()));
    await Future.wait([first, second]);

    // Assert
    verify(() => repository.restoreOrder(7)).called(1);
  });

  // ───────────────────────────── the preview the screen cannot compose ─────────────────────

  test('the preview is fetched when the order on screen carries none', () async {
    // Arrange — exactly what [replace] leaves behind: `stock_effect` is sent by show, destroy
    // and restore alone, so the order a status change answers with has none.
    when(
      () => repository.order(7),
    ).thenAnswer((_) async => Right(orderWith(effect: preview)));
    await cubit.load();
    cubit.replace(orderWith());

    // Act
    final failure = await cubit.refreshStockEffect();

    // Assert — the one request this screen is allowed: the preview is read off the movement
    // ledger, and no amount of arithmetic in Dart can reconstruct it.
    expect(failure, isNull);
    expect(cubit.state.order?.stockEffect, isNotNull);
    verify(() => repository.order(7)).called(2);
  });

  test('a re-read for the preview hands its refusal back rather than parking it', () async {
    // Arrange — parking it would put the screen in `OrderDetailFailure`, whose listener toasts
    // it too, so the reader would be told the same thing twice.
    when(
      () => repository.order(7),
    ).thenAnswer((_) async => Right(orderWith(effect: preview)));
    await cubit.load();
    cubit.replace(orderWith());
    when(() => repository.order(7)).thenAnswer(
      (_) async => const Left(Failure.network(message: 'تعذّر الاتصال بالخادم')),
    );

    // Act
    final failure = await cubit.refreshStockEffect();

    // Assert — the order the screen was showing is still the order it is showing.
    expect(failure?.message, 'تعذّر الاتصال بالخادم');
    expect(cubit.state, isA<OrderDetailLoaded>());
    expect(cubit.state.order?.code, '7');
  });

  test('judging a version re-reads the order, because what follows it has changed', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    when(
      () => repository.reviewDesign(
        7,
        4,
        isApproved: any(named: 'isApproved'),
        rejectionReason: any(named: 'rejectionReason'),
      ),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final failure = await cubit.reviewDesign(4, isApproved: true);

    // Assert — an approved version is what lets the order be printed, and whether it may now
    // is the server's answer rather than this app's inference.
    expect(failure, isNull);
    verify(() => repository.order(7)).called(2);
  });
}
