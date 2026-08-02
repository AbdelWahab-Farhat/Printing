import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/change_order_status.dart';
import 'package:printing/features/orders/usecases/get_order.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late OrderDetailCubit cubit;

  Order orderWith({
    OrderStatus status = OrderStatus.ready,
    String label = 'جاهزة',
    List<OrderTransition> transitions = const [],
  }) {
    return Order(
      id: 7,
      code: '7',
      status: status,
      statusLabel: label,
      isFinal: false,
      availableTransitions: transitions,
      customerId: 5,
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
      changeStatus: ChangeOrderStatus(repository),
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

  // ───────────────────────────── moving ─────────────────────────────

  test('a successful move keeps the order the server returned', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();

    final moved = orderWith(status: OrderStatus.printing, label: 'قيد الطباعة');
    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => Right(moved));

    // Act
    final result = await cubit.move(OrderStatus.printing);

    // Assert — the response *is* the new order, including a different set of legal moves, so
    // taking it is one round trip instead of two.
    expect(result?.statusLabel, 'قيد الطباعة');
    expect(cubit.state.order?.statusLabel, 'قيد الطباعة');
    expect(cubit.state.isMoving, isFalse);
  });

  test('a refused move leaves the order on screen', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        Failure.server(
          message: 'لا يمكن نقل الطلبية من «جاهزة» إلى «تم الاستلام»',
        ),
      ),
    );

    // Act
    final result = await cubit.move(OrderStatus.delivered);

    // Assert — the screen keeps what it was showing, with the server's sentence over the top.
    expect(result, isNull);
    expect(cubit.state, isA<OrderDetailFailure>());
    expect(cubit.state.order?.statusLabel, 'جاهزة');
  });

  test('a blank reason is not sent at all', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer((_) async => Right(orderWith()));
    await cubit.load();
    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => Right(orderWith()));

    // Act — a field the user tabbed through and left as spaces.
    await cubit.move(OrderStatus.printing, reason: '   ');

    // Assert — sending it would satisfy a required-field check while telling the next reader
    // nothing.
    final captured = verify(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: captureAny(named: 'reason'),
      ),
    ).captured.last;

    expect(captured, isNull);
  });

  test('moving before the order has loaded does nothing', () async {
    // Act
    final result = await cubit.move(OrderStatus.printing);

    // Assert
    expect(result, isNull);
    verifyNever(
      () => repository.changeStatus(
        any(),
        status: any(named: 'status'),
        reason: any(named: 'reason'),
      ),
    );
  });
}
