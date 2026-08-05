// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/models/orders_filter.dart';
import 'package:printing/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// The orders behind one number on the home screen.
///
/// **What is worth proving is that the tap and the number agree.** A card saying «نواقص ١٤» that
/// opens a list of forty is worse than a card that does nothing, and the two ways that happens
/// are asking for the wrong statuses and forgetting the filter on page two.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;

  setUp(() => repository = _MockOrderRepository());

  Order orderWith({int id = 1, OrderStatus status = OrderStatus.shortage}) {
    return Order(
      id: id,
      code: '$id',
      status: status,
      statusLabel: 'نواقص',
      isFinal: false,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '100.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: '0.00',
      grandTotal: '120.00',
    );
  }

  void stub({List<Order> orders = const []}) {
    when(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<Order>(
          items: orders,
          meta: PageMeta(
            currentPage: 1,
            perPage: 20,
            lastPage: 2,
            total: orders.length,
          ),
        ),
      ),
    );
  }

  FilteredOrdersCubit cubitFor(OrdersFilter filter) =>
      FilteredOrdersCubit(getOrders: GetOrders(repository), filter: filter);

  test('a status card asks for exactly the status it counted', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );

    // Act
    await cubit.load();

    // Assert — one status, not the «رواجع»-shaped group a queue chip would have selected.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, ['shortage']);
  });

  test('a day card asks for that day at both ends', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'طلبات اليوم', from: '2026-08-06', to: '2026-08-06'),
    );

    // Act
    await cubit.load();

    // Assert — plain days: where a day begins is the server's business, since it is the one
    // that knows the shop's timezone.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        customerId: any(named: 'customerId'),
        from: captureAny(named: 'from'),
        to: captureAny(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured, ['2026-08-06', '2026-08-06']);
  });

  test('page two carries the same filter as page one', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act
    await cubit.loadMore();

    // Assert — a second page of everything appended to a first page of «نواقص» is a list that
    // stops matching its own title halfway down.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured.last, ['shortage']);
  });

  test('an order moved out of this answer leaves the screen', () async {
    // Arrange
    stub(orders: [orderWith(id: 1), orderWith(id: 2)]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act — the shortage was resolved while the detail screen was open.
    cubit.replace(orderWith(id: 1, status: OrderStatus.ready));

    // Assert — a row contradicting the title above it is worse than a row that vanished.
    final state = cubit.state as PagedLoaded<Order>;
    expect(state.page.items.map((order) => order.id), [2]);
  });

  test('an order that still belongs is updated in place', () async {
    // Arrange
    stub(orders: [orderWith(id: 1)]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act — it went in and out of «نواقص» and came back to it.
    cubit.replace(orderWith(id: 1));

    // Assert
    final state = cubit.state as PagedLoaded<Order>;
    expect(state.page.items, hasLength(1));
    expect(state.page.items.single.id, 1);
  });
}
