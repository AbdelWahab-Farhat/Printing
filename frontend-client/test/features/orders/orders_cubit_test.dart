import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/browse_orders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  const first = CustomerOrder(
    id: 1,
    code: '1231',
    stage: OrderStage.underReview,
    stageLabel: 'بانتظار المراجعة',
    total: '4250.000',
  );
  const second = CustomerOrder(
    id: 2,
    code: '1228',
    stage: OrderStage.producing,
    stageLabel: 'قيد الإنتاج',
    total: '2800.000',
  );

  Paginated<CustomerOrder> page(
    List<CustomerOrder> items, {
    int current = 1,
    int last = 1,
  }) => Paginated<CustomerOrder>(
    items: items,
    meta: PageMeta(
      currentPage: current,
      perPage: 15,
      lastPage: last,
      total: items.length,
    ),
  );

  setUp(() => repository = _MockOrderRepository());

  OrdersCubit build() => OrdersCubit(browse: BrowseOrders(repository));

  void stub(Paginated<CustomerOrder> result) {
    when(
      () => repository.list(page: any(named: 'page'), openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
    ).thenAnswer((_) async => Right(result));
  }

  group('load', () {
    blocTest<OrdersCubit, OrdersState>(
      'emits loading then the first page',
      build: () {
        stub(page([first, second]));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const PagedState<CustomerOrder>.loading(),
        PagedState<CustomerOrder>.loaded(page: page([first, second])),
      ],
    );

    /// The filter is asked in *stages* — the customer's vocabulary — and the server translates.
    /// This app never learns the workshop's nineteen statuses.
    blocTest<OrdersCubit, OrdersState>(
      'narrowing to the open ones passes the filter through',
      build: () {
        stub(page([first]));

        return build();
      },
      act: (cubit) => cubit.narrowTo(OrdersFilter.open),
      verify: (cubit) {
        verify(() => repository.list(page: 1, openOnly: true, stage: null)).called(1);
        expect(cubit.filter, OrdersFilter.open);
      },
    );

    /// **«طلباتي» has no search endpoint**, so the term the base class threads through is
    /// dropped rather than sent to be silently ignored.
    blocTest<OrdersCubit, OrdersState>(
      'a search term never reaches the wire',
      build: () {
        stub(page([first]));

        return build();
      },
      act: (cubit) => cubit.load(search: 'كيس'),
      verify: (_) {
        verify(() => repository.list(page: 1, openOnly: false, stage: null)).called(1);
      },
    );
  });

  group('loadMore', () {
    blocTest<OrdersCubit, OrdersState>(
      'appends the next page and keeps what was already there',
      build: () {
        when(
          () => repository.list(page: 1, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
        ).thenAnswer((_) async => Right(page([first], last: 2)));
        when(
          () => repository.list(page: 2, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
        ).thenAnswer((_) async => Right(page([second], current: 2, last: 2)));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      verify: (cubit) {
        final state = cubit.state as PagedLoaded<CustomerOrder>;

        expect(state.page.items, [first, second]);
        expect(state.page.hasMore, isFalse);
      },
    );

    /// **A list that fires a second request while the first is in flight appends the same page
    /// twice** — which on a phone looks like the app duplicating the customer's orders.
    blocTest<OrdersCubit, OrdersState>(
      'ignores a second request while one is already in flight',
      build: () {
        when(
          () => repository.list(page: 1, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
        ).thenAnswer((_) async => Right(page([first], last: 2)));
        when(() => repository.list(page: 2, openOnly: any(named: 'openOnly'), stage: any(named: 'stage'))).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));

          return Right(page([second], current: 2, last: 2));
        });

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        unawaited(cubit.loadMore());
        unawaited(cubit.loadMore());
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) {
        verify(() => repository.list(page: 2, openOnly: any(named: 'openOnly'), stage: any(named: 'stage'))).called(1);
      },
    );

    blocTest<OrdersCubit, OrdersState>(
      'does nothing when there is no next page',
      build: () {
        stub(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      verify: (_) {
        verify(() => repository.list(page: 1, openOnly: any(named: 'openOnly'), stage: any(named: 'stage'))).called(1);
        verifyNever(() => repository.list(page: 2, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')));
      },
    );

    /// Losing the orders already on screen because page three timed out would be the app
    /// throwing away what it has.
    blocTest<OrdersCubit, OrdersState>(
      'a failed next page keeps the orders already loaded',
      build: () {
        when(
          () => repository.list(page: 1, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
        ).thenAnswer((_) async => Right(page([first], last: 2)));
        when(
          () => repository.list(page: 2, openOnly: any(named: 'openOnly'), stage: any(named: 'stage')),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      verify: (cubit) {
        final state = cubit.state as PagedLoaded<CustomerOrder>;

        expect(state.page.items, [first]);
        expect(state.isLoadingMore, isFalse);
      },
    );
  });

  /// **The filter must not become a lie.** An order that closed while «المفتوحة» is selected
  /// leaves the list rather than sitting there until the next refresh.
  group('belongs', () {
    blocTest<OrdersCubit, OrdersState>(
      'an order that closed leaves a list narrowed to the open ones',
      build: () {
        stub(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.narrowTo(OrdersFilter.open);
        cubit.replace(first.copyWith(isOpen: false));
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<CustomerOrder>).page.items, isEmpty);
      },
    );

    blocTest<OrdersCubit, OrdersState>(
      'and stays when the list is showing everything',
      build: () {
        stub(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        cubit.replace(first.copyWith(isOpen: false));
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<CustomerOrder>).page.items.single.isOpen, isFalse);
      },
    );
  });

  /// **The stage the workshop's vocabulary never reaches.** An order from the app is born
  /// «بانتظار المراجعة», and the label travels with the value so a stage added to the business
  /// appears without an app release.
  test('an order carries the stage and the Arabic the server sent', () {
    expect(first.stage, OrderStage.underReview);
    expect(first.stageLabel, 'بانتظار المراجعة');
  });

  /// A stage this build has not heard of must not crash the list — it is drawn with the label
  /// the server sent.
  test('an unknown stage falls back rather than throwing', () {
    final parsed = CustomerOrder.fromJson(const {
      'id': 9,
      'code': '1300',
      'stage': 'something_new',
      'stage_label': 'حالة جديدة',
      'total': '10.00',
    });

    expect(parsed.stage, OrderStage.unknown);
    expect(parsed.stageLabel, 'حالة جديدة');
  });
}
