import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/archived_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_archived_orders.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// الأرشيف, and the two lists correcting each other with no request between them.
///
/// **This is the whole of §٨, and it is why the app side of the feature is nearly free.**
/// [PagedCubit.belongs] and [PagedCubit.replace] were already built and already paired — a row
/// that no longer belongs is dropped rather than redrawn — so «حُذفت» and «استُعيدت» are one
/// field on the model apiece. الطلبيات refuses a row with a `deleted_at`; الأرشيف refuses one
/// without. The detail screen hands the mutated order to whichever list it was opened from, and
/// that list takes the row off itself.
///
/// **And there is deliberately no `insert()` for a restored order.** `insert`'s own docblock
/// says it is for lists the server returns `id DESC` and counts the orders among them — that is
/// a slip: `OrderListQuery` orders by `placed_at` then `id`, and the direction turns over under
/// «الأقدم أولاً». Putting a restored order at the top would be the app guessing at a position
/// the next page load would contradict. It arrives on the next load instead.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  setUpAll(() => registerFallbackValue(OrdersSort.newest));

  late _MockOrderRepository repository;

  Order orderWith({
    int id = 1,
    OrderStatus status = OrderStatus.ready,
    DateTime? deletedAt,
  }) {
    return Order(
      id: id,
      code: '$id',
      status: status,
      statusLabel: 'جاهزة',
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
      deletedAt: deletedAt,
    );
  }

  Paginated<Order> pageOf(List<Order> orders) => Paginated<Order>(
    items: orders,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: orders.length),
  );

  /// Both sources answered, because both cubits fetch their page and their counts together —
  /// a fake that stubbed one would leave the other throwing for a reason no test is about.
  void stubLive(List<Order> orders) {
    when(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer(
      (_) async => const Right(OrderCounts(byStatus: {'ready': 1}, total: 1)),
    );
    when(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(pageOf(orders)));
  }

  void stubArchive(List<Order> orders) {
    when(
      () => repository.archivedStatusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer(
      (_) async => const Right(OrderCounts(byStatus: {'ready': 1}, total: 1)),
    );
    when(
      () => repository.archivedOrders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(pageOf(orders)));
  }

  ArchivedOrdersCubit archiveCubit() => ArchivedOrdersCubit(
    getOrders: GetArchivedOrders(repository),
    getCounts: GetArchivedOrderCounts(repository),
  );

  OrdersCubit liveCubit() => OrdersCubit(
    getOrders: GetOrders(repository),
    getCounts: GetOrderCounts(repository),
  );

  setUp(() => repository = _MockOrderRepository());

  group('the archive reads the archive', () {
    test('its page comes from the archive route, never the live one', () async {
      // Arrange
      stubArchive([orderWith(deletedAt: DateTime(2026, 9, 10))]);
      final cubit = archiveCubit();

      // Act
      await cubit.load();

      // Assert
      verify(
        () => repository.archivedOrders(
          search: any(named: 'search'),
          statuses: any(named: 'statuses'),
          paymentStatuses: any(named: 'paymentStatuses'),
          isUrgent: any(named: 'isUrgent'),
          sort: any(named: 'sort'),
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
      verifyNever(
        () => repository.orders(
          search: any(named: 'search'),
          statuses: any(named: 'statuses'),
          paymentStatuses: any(named: 'paymentStatuses'),
          isUrgent: any(named: 'isUrgent'),
          sort: any(named: 'sort'),
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      );

      await cubit.close();
    });

    test('its chips are counted over the archive too', () async {
      // Arrange — §٦'s worst failure is two rows of numbers describing two different sets, and
      // it happens the moment one of the three seeded queries is left pointing at the live list.
      stubArchive(const []);
      final cubit = archiveCubit();

      // Act
      await cubit.load();

      // Assert
      verify(
        () => repository.archivedStatusCounts(
          search: any(named: 'search'),
          customerId: any(named: 'customerId'),
        ),
      ).called(1);
      verifyNever(
        () => repository.statusCounts(
          search: any(named: 'search'),
          customerId: any(named: 'customerId'),
        ),
      );

      await cubit.close();
    });

    test('its chips carry the numbers the archive summary answered', () async {
      // Arrange — verifying the *call* only proves the request went to the right place; what
      // the filter sheet draws is this notifier, and a count fetched and then dropped on the
      // floor would pass the test above and still show «٠» beside «إلغاء تام».
      when(
        () => repository.archivedStatusCounts(
          search: any(named: 'search'),
          customerId: any(named: 'customerId'),
        ),
      ).thenAnswer(
        (_) async => const Right(OrderCounts(byStatus: {'cancelled': 4}, total: 4)),
      );
      when(
        () => repository.archivedOrders(
          search: any(named: 'search'),
          statuses: any(named: 'statuses'),
          paymentStatuses: any(named: 'paymentStatuses'),
          isUrgent: any(named: 'isUrgent'),
          sort: any(named: 'sort'),
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(pageOf(const [])));
      final cubit = archiveCubit();

      // Act
      await cubit.load();
      // The counts are deliberately not awaited with the page — see [OrdersCubit.load] — so the
      // microtask they were kicked off in has to be let go of before they are read.
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(cubit.counts.value.total, 4);
      expect(cubit.counts.value.byStatus['cancelled'], 4);

      await cubit.close();
    });

    test('it narrows by the same axes the orders screen does', () async {
      // Arrange — the reason the archive mirrors OrdersCubit rather than FilteredOrdersPage:
      // `OrdersFilter` has six fields, no urgency and no search, so it cannot carry the
      // question the reader actually asked.
      stubArchive(const []);
      final cubit = archiveCubit();
      await cubit.load();

      // Act
      await cubit.showFilters(
        status: OrderStatus.cancelled,
        paymentStatuses: const {},
        isUrgent: true,
      );

      // Assert
      verify(
        () => repository.archivedOrders(
          search: any(named: 'search'),
          statuses: ['cancelled'],
          paymentStatuses: any(named: 'paymentStatuses'),
          isUrgent: true,
          sort: any(named: 'sort'),
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);

      await cubit.close();
    });
  });

  group('the two lists correct themselves', () {
    blocTest<OrdersCubit, OrdersState>(
      'الطلبيات drops an order that has just been archived',
      setUp: () => stubLive([orderWith(id: 1), orderWith(id: 2)]),
      build: liveCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.replace(orderWith(id: 1, deletedAt: DateTime(2026, 9, 10)));
      },
      verify: (cubit) {
        // Assert — one request for the page, none for the drop.
        final state = cubit.state as OrdersLoaded;

        expect(state.page.items.map((order) => order.id), [2]);
      },
    );

    blocTest<ArchivedOrdersCubit, OrdersState>(
      'الأرشيف drops an order that has just been restored',
      setUp: () => stubArchive([
        orderWith(id: 1, deletedAt: DateTime(2026, 9, 10)),
        orderWith(id: 2, deletedAt: DateTime(2026, 9, 10)),
      ]),
      build: archiveCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.replace(orderWith(id: 1));
      },
      verify: (cubit) {
        final state = cubit.state as OrdersLoaded;

        expect(state.page.items.map((order) => order.id), [2]);
      },
    );

    test('neither drop costs a page request — the list already held the answer', () async {
      // Arrange — this is the whole of §٨. `belongs` is answered from the row in hand, so the
      // detail screen handing back a trashed order is the complete transaction: no GET, no
      // re-paginating, no moment where the row is on screen and stale.
      stubLive([orderWith(id: 1), orderWith(id: 2)]);
      final cubit = liveCubit();
      await cubit.load();
      clearInteractions(repository);

      // Act
      cubit.replace(orderWith(id: 1, deletedAt: DateTime(2026, 9, 10)));

      // Assert — not one more page fetched.
      verifyNever(
        () => repository.orders(
          search: any(named: 'search'),
          statuses: any(named: 'statuses'),
          paymentStatuses: any(named: 'paymentStatuses'),
          isUrgent: any(named: 'isUrgent'),
          sort: any(named: 'sort'),
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      );
      expect((cubit.state as OrdersLoaded).page.items.map((order) => order.id), [2]);

      await cubit.close();
    });

    test('الأرشيف keeps a row that only changed status', () async {
      // Arrange — `belongs` crosses the soft-delete line with every axis the live list has, so
      // an archived order edited into the queue on screen must stay on it.
      stubArchive([orderWith(id: 1, deletedAt: DateTime(2026, 9, 10))]);
      final cubit = archiveCubit();
      await cubit.load();

      // Act
      cubit.replace(
        orderWith(id: 1, status: OrderStatus.cancelled, deletedAt: DateTime(2026, 9, 10)),
      );

      // Assert
      final state = cubit.state as OrdersLoaded;

      expect(state.page.items.single.status, OrderStatus.cancelled);

      await cubit.close();
    });

    test('a restored order is not inserted at the top of the live list', () async {
      // Arrange — see the class doc: `insert`'s «id DESC» is not true of this list, and the
      // direction turns over under «الأقدم أولاً». It arrives on the next load.
      stubLive([orderWith(id: 2)]);
      final cubit = liveCubit();
      await cubit.load();

      // Act — the row is not on the pages loaded, so `replace` is a no-op by design.
      final moved = cubit.replace(orderWith(id: 9));

      // Assert
      final state = cubit.state as OrdersLoaded;

      expect(moved, isFalse);
      expect(state.page.items.map((order) => order.id), [2]);

      await cubit.close();
    });
  });
}
