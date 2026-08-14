import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
