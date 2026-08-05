import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/get_order_counts.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';

/// The orders list's ViewModel. The repository is faked, nothing touches Dio, and the
/// assertions are on the sequence of states the screen would have rendered.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late OrdersCubit cubit;

  Order orderWith({
    int id = 1,
    OrderStatus status = OrderStatus.ready,
    String label = 'جاهزة',
  }) {
    return Order(
      id: id,
      code: '$id',
      status: status,
      statusLabel: label,
      isFinal: false,
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

  Paginated<Order> pageOf(List<Order> orders, {int currentPage = 1, int lastPage = 1}) {
    return Paginated<Order>(
      items: orders,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: orders.length,
      ),
    );
  }

  /// The list and the counts are fetched together, so a fake that only answers one of them
  /// leaves the other throwing — which would fail every test for a reason none of them is about.
  void stubCounts({Map<String, int>? byStatus, Failure? failure}) {
    when(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer(
      (_) async => failure != null
          ? Left(failure)
          : Right(
              OrderCounts(
                byStatus: byStatus ?? const <String, int>{'ready': 2, 'printing': 1},
                total: 3,
              ),
            ),
    );
  }

  void stub({List<Order>? orders, Failure? failure, int lastPage = 1}) {
    stubCounts();

    when(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => failure != null
          ? Left(failure)
          : Right(pageOf(orders ?? const <Order>[], lastPage: lastPage)),
    );
  }

  setUp(() {
    repository = _MockOrderRepository();
    cubit = OrdersCubit(
      getOrders: GetOrders(repository),
      getCounts: GetOrderCounts(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── loading ─────────────────────────────

  blocTest<OrdersCubit, OrdersState>(
    'emits loading then loaded on a successful first page',
    build: () {
      // Arrange
      stub(orders: [orderWith()]);

      return cubit;
    },
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<OrdersLoading>(),
      isA<OrdersLoaded>().having((s) => s.page.items.length, 'items', 1),
    ],
  );

  blocTest<OrdersCubit, OrdersState>(
    "shows the server's own message when the list fails",
    build: () {
      // Arrange — the failure carries Arabic the backend took trouble to write.
      stub(failure: const Failure.forbidden(message: 'لا تملك صلاحية عرض الطلبيات'));

      return cubit;
    },
    // Act
    act: (cubit) => cubit.load(),
    // Assert — never replaced with a generic apology.
    expect: () => [
      isA<OrdersLoading>(),
      isA<OrdersFailure>().having(
        (s) => s.failure.message,
        'message',
        'لا تملك صلاحية عرض الطلبيات',
      ),
    ],
  );

  blocTest<OrdersCubit, OrdersState>(
    'an empty list is a loaded state, not a failure',
    build: () {
      // Arrange
      stub(orders: const <Order>[]);

      return cubit;
    },
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<OrdersLoading>(),
      isA<OrdersLoaded>().having((s) => s.page.isEmpty, 'isEmpty', true),
    ],
  );

  // ───────────────────────────── the queues ─────────────────────────────

  test('a queue sends every status it covers, not just one', () async {
    // Arrange
    stub(orders: [orderWith()]);

    // Act
    await cubit.showQueue(OrderQueue.returned);

    // Assert — «رواجع» is four statuses; asking for one of them would hide the rest. The parcel
    // being sent out again is still a parcel that came back, and it is still on our shelf.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, [
      'returned_courier',
      'returned_carrier',
      'returned_office',
      'resend',
    ]);
  });

  test('«الكل» sends no status filter at all', () async {
    // Arrange
    stub(orders: [orderWith()]);

    // Act
    await cubit.load();

    // Assert
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, isEmpty);
  });

  test('changing the queue keeps the search term', () async {
    // Arrange
    stub(orders: [orderWith()]);
    await cubit.load(search: 'أحمد');

    // Act
    await cubit.showQueue(OrderQueue.ready);

    // Assert — narrowing a question is not asking a new one.
    final captured = verify(
      () => repository.orders(
        search: captureAny(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, 'أحمد');
  });

  test('selecting the queue already showing does not refetch', () async {
    // Arrange
    stub(orders: [orderWith()]);
    await cubit.load();
    clearInteractions(repository);

    // Act
    await cubit.showQueue(OrderQueue.all);

    // Assert
    verifyNever(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    );
  });

  // ─────────────────────── replacing a row after a move ───────────────────────

  test('a moved order replaces its row in place', () async {
    // Arrange
    stub(orders: [orderWith(id: 1), orderWith(id: 2)]);
    await cubit.load();

    // Act
    cubit.replace(
      orderWith(id: 1, status: OrderStatus.printing, label: 'قيد الطباعة'),
    );

    // Assert — the row updates without the list scrolling back to page one.
    final state = cubit.state as OrdersLoaded;
    expect(state.page.items.first.statusLabel, 'قيد الطباعة');
    expect(state.page.items.length, 2);
  });

  test('an order that left the selected queue drops off the list', () async {
    // Arrange
    stub(orders: [orderWith(id: 1), orderWith(id: 2)]);
    await cubit.showQueue(OrderQueue.ready);

    // Act — marked delivered while «جاهزة» is the queue on screen.
    cubit.replace(
      orderWith(id: 1, status: OrderStatus.delivered, label: 'تم الاستلام'),
    );

    // Assert — leaving it visible would make the chip a lie until the next refresh.
    final state = cubit.state as OrdersLoaded;
    expect(state.page.items.map((o) => o.id), [2]);
  });

  test('replacing does nothing before a page has loaded', () {
    // Act & Assert — no throw, and nothing to show.
    cubit.replace(orderWith());

    expect(cubit.state, isA<OrdersInitial>());
  });

  // ───────────────── the numbers beside the filter ─────────────────

  test('the counts arrive with the first page', () async {
    // Arrange
    stub(orders: [orderWith()]);
    stubCounts(byStatus: {'ready': 4, 'printing': 2});

    // Act
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(cubit.counts.value.byStatus['ready'], 4);
  });

  test('a queue is counted as the sum of the statuses it covers', () async {
    // Arrange
    stub(orders: [orderWith()]);
    stubCounts(
      byStatus: {
        'returned_courier': 2,
        'returned_carrier': 1,
        'returned_office': 3,
        'ready': 9,
      },
    );
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    // Act
    final returned = cubit.counts.value.forQueue(OrderQueue.returned);

    // Assert — «رواجع» is three statuses, and the server counts by status.
    expect(returned, 6);
  });

  test('changing the queue does not refetch the counts', () async {
    // Arrange
    stub(orders: [orderWith()]);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(repository);

    // Act
    await cubit.showQueue(OrderQueue.ready);
    await Future<void>.delayed(Duration.zero);

    // Assert — the numbers describe the unfiltered set, so picking a queue cannot move them.
    verifyNever(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    );
  });

  test('a new search does refetch them', () async {
    // Arrange
    stub(orders: [orderWith()]);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(repository);

    // Act — the search is the one filter that changes what there is to count.
    await cubit.load(search: 'أحمد');
    await Future<void>.delayed(Duration.zero);

    // Assert
    verify(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).called(1);
  });

  test('a failed count leaves the last numbers standing', () async {
    // Arrange
    stub(orders: [orderWith()]);
    stubCounts(byStatus: {'ready': 7});
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    stubCounts(failure: const Failure.network(message: 'لا يوجد اتصال'));

    // Act
    await cubit.load(search: 'أحمد');
    await Future<void>.delayed(Duration.zero);

    // Assert — the list is what the user came for; a missing number is a smaller lie than a
    // zero that claims there is nothing there.
    expect(cubit.counts.value.byStatus['ready'], 7);
  });

  test('closing twice does not throw', () async {
    // Arrange
    stub(orders: [orderWith()]);
    await cubit.load();

    // Act & Assert — `Cubit.close()` is idempotent and callers rely on it; the notifier inside
    // must not take that away.
    await cubit.close();
    await expectLater(cubit.close(), completes);
  });

  // ───────────────────────────── paging ─────────────────────────────

  test('a failed extra page keeps what is already on screen', () async {
    // Arrange
    stub(orders: [orderWith(id: 1)], lastPage: 2);
    await cubit.load();

    when(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.network(message: 'لا يوجد اتصال')),
    );

    // Act
    await cubit.loadMore();

    // Assert — losing a working list because page two failed is the worse answer.
    final state = cubit.state as OrdersLoaded;
    expect(state.page.items.length, 1);
    expect(state.isLoadingMore, isFalse);
  });
}
