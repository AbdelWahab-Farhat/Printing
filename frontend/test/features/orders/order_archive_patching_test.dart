// dartz exports an `Order` of its own (its ordering typeclass, which this app never uses).
// Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/carrier/usecases/release_shipment.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/models/stock_effect.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/archived_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/archived_orders_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_archived_orders.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// The list and the detail screen, joined — which is the half of §٨ neither one can prove alone.
///
/// **`belongs()` and `handBack()` are each already tested, and neither test says the feature
/// works.** `archived_orders_cubit_test.dart` proves a cubit handed a trashed order drops it;
/// the actions tests prove the screen sends the delete and stays open on the archived order.
/// What sits between them is a chain of four links — `pushForResult` makes the slot,
/// `handBack` writes the order into it, the push returns, `cubit.replace` reads it — and any
/// one of them going missing is a row that stays on screen after it was deleted, with nothing
/// red anywhere to say so.
///
/// **And the count of requests is the assertion, not a detail of it.** «Lists patch, they do
/// not refresh» is the rule this feature was built on: the delete's response *is* the order, so
/// the list behind already holds every fact it needs to take the row off itself. A `load()` on
/// the way back would work, look identical on screen, and quietly make the rule false.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  setUpAll(() => registerFallbackValue(OrdersSort.newest));

  late _MockOrderRepository repository;

  /// The delete's preview, and the restore's — the server's words, carried rather than written.
  const returning = StockEffect(
    stock: WarehouseEffect(
    kind: StockEffectKind.returnToShelf,
    warning: 'سيُعاد إلى المخزن ما خصمته هذه الطلبية:',
    lines: [StockEffectLine(label: 'كيس شحن 25*35', quantity: '300', unit: 'قطعة')],
    ),
  );

  const rededucting = StockEffect(
    stock: WarehouseEffect(
    kind: StockEffectKind.rededuct,
    warning: 'سيُخصم من المخزن من جديد:',
    lines: [StockEffectLine(label: 'كيس شحن 25*35', quantity: '300', unit: 'قطعة')],
    note: 'وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم',
    ),
  );

  Order order({int id = 55, DateTime? deletedAt, StockEffect? effect}) => Order(
    id: id,
    code: '$id',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
    deletedAt: deletedAt,
    stockEffect: effect,
  );

  Paginated<Order> pageOf(List<Order> rows) => Paginated<Order>(
    items: rows,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: rows.length),
  );

  /// Both lists' sources answered, because the two screens under test each fetch a page and a
  /// set of counts, and an unstubbed one would throw for a reason none of these tests is about.
  Future<void> arrange({
    required List<Order> live,
    required List<Order> archived,
    required List<String> permissions,
    required Order opened,
  }) async {
    await Injector.reset();

    repository = _MockOrderRepository();

    when(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => const Right(OrderCounts(byStatus: {'ready': 1}, total: 1)));
    when(
      () => repository.archivedStatusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => const Right(OrderCounts(byStatus: {'ready': 1}, total: 1)));
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
    ).thenAnswer((_) async => Right(pageOf(live)));
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
    ).thenAnswer((_) async => Right(pageOf(archived)));
    when(() => repository.order(55)).thenAnswer((_) async => Right(opened));

    final carrier = _MockCarrierRepository();

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: permissions,
            ),
          ),
      )
      ..registerLazySingleton<UpdateOrderInvoice>(() => UpdateOrderInvoice(repository))
      // Registered and never reached, as `send_to_carrier_visibility_test.dart` does it: a
      // missing registration would fail these for a reason none of them is about.
      ..registerLazySingleton<LodgeOrder>(() => LodgeOrder(carrier))
      ..registerLazySingleton<ResendCarrierShipment>(() => ResendCarrierShipment(carrier))
      ..registerLazySingleton<DeleteCarrierShipment>(() => DeleteCarrierShipment(carrier))
      ..registerLazySingleton<UnlinkCarrierShipment>(() => UnlinkCarrierShipment(carrier))
      ..registerFactory<OrdersCubit>(
        () => OrdersCubit(
          getOrders: GetOrders(repository),
          getCounts: GetOrderCounts(repository),
        ),
      )
      ..registerFactory<ArchivedOrdersCubit>(
        () => ArchivedOrdersCubit(
          getOrders: GetArchivedOrders(repository),
          getCounts: GetArchivedOrderCounts(repository),
        ),
      )
      ..registerFactoryParam<OrderInvoiceCubit, Order, void>(
        (order, _) => OrderInvoiceCubit(order: order, updateInvoice: sl<UpdateOrderInvoice>()),
      )
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: GetOrder(repository),
          addDesign: AddOrderDesign(repository),
          reviewDesign: ReviewOrderDesign(repository),
          reinstateOrder: ReinstateOrder(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
        ),
      );
  }

  /// The real router, because `pushForResult` is the thing being tested: it hangs its slot on
  /// the route's own `extra`, so a bare `Navigator` would carry nothing and every one of these
  /// would pass by doing nothing at all.
  late GoRouter router;

  Widget host(Widget list) {
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => list),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  /// How many pages of the live list were asked for. The first is the one that drew the screen.
  int livePageReads() => verify(
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
  ).callCount;

  int archivePageReads() => verify(
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
  ).callCount;

  /// Opens the row, works the dial and confirms — the whole gesture, from the list and back.
  Future<void> takeTheRowThrough(
    WidgetTester tester, {
    required String arm,
    required String confirm,
  }) async {
    await tester.tap(find.byType(OrderCard).first);
    await tester.pumpAndSettle();

    // The step §٨ warns about: [AppSpeedDial] draws one surviving action as a plain extended
    // button and two or more as a closed dial, so the label is not on screen until it is opened.
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(arm));
    await tester.pumpAndSettle();

    await tester.tap(find.text(confirm).last);
    await tester.pumpAndSettle();

    // Left the way a detail screen is really left — the pop carries nothing, and the row
    // travels beside the route instead. Popped through the router rather than by finding a back
    // button: the confirmation toast floats over the corner the header's arrow sits in, and a
    // test that tapped through a snackbar would be testing the snackbar's timer.
    router.pop();
    // The toast the screen raised outlives the screen — it is an overlay entry with a timer of
    // its own — and a timer still pending when the tree is torn down fails the test for a
    // reason it is not about.
    resetSnackBars();
    await tester.pumpAndSettle();
  }

  tearDown(Injector.reset);

  testWidgets('deleting an order takes its row off الطلبيات, with no second page', (
    tester,
  ) async {
    // Arrange — two rows on screen, and the one about to be deleted is the first.
    await arrange(
      live: [order(), order(id: 56)],
      archived: const [],
      permissions: ['orders.view', 'orders.payments.view', 'orders.delete'],
      opened: order(effect: returning),
    );
    when(() => repository.deleteOrder(55)).thenAnswer(
      (_) async => Right(order(deletedAt: DateTime(2026, 9, 10), effect: rededucting)),
    );
    await tester.pumpWidget(host(const OrdersPage()));
    await tester.pumpAndSettle();

    // Act
    await takeTheRowThrough(tester, arm: 'حذف الطلبية', confirm: 'حذف');

    // Assert — one row left, and the list was never asked for again: the trashed order it was
    // handed is the whole answer.
    expect(find.byType(OrderCard), findsOneWidget);
    expect(tester.widget<OrderCard>(find.byType(OrderCard)).order.id, 56);
    expect(livePageReads(), 1);
  });

  testWidgets('restoring an order takes its row off الأرشيف, with no second page', (
    tester,
  ) async {
    // Arrange — the mirror image, and the reason الأرشيف is [OrdersCubit] with one comparison
    // turned round rather than a screen of its own.
    await arrange(
      live: const [],
      archived: [
        order(deletedAt: DateTime(2026, 9, 10)),
        order(id: 56, deletedAt: DateTime(2026, 9, 10)),
      ],
      permissions: ['orders.view', 'orders.payments.view', 'orders.restore'],
      opened: order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    when(
      () => repository.restoreOrder(55),
    ).thenAnswer((_) async => Right(order(effect: returning)));
    await tester.pumpWidget(host(const ArchivedOrdersPage()));
    await tester.pumpAndSettle();

    // Act
    await takeTheRowThrough(tester, arm: 'استعادة الطلبية', confirm: 'استعادة');

    // Assert
    expect(find.byType(OrderCard), findsOneWidget);
    expect(tester.widget<OrderCard>(find.byType(OrderCard)).order.id, 56);
    expect(archivePageReads(), 1);
  });

  testWidgets('a delete the server refused leaves the row exactly where it was', (
    tester,
  ) async {
    // Arrange — «لا شيء تغيّر» has to reach the list too. The detail screen puts the order back
    // as it was and hands *that* over, so the row redraws itself rather than disappearing on
    // the strength of a request that failed.
    await arrange(
      live: [order(), order(id: 56)],
      archived: const [],
      permissions: ['orders.view', 'orders.payments.view', 'orders.delete'],
      opened: order(effect: returning),
    );
    when(() => repository.deleteOrder(55)).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن حذف طلبية لها طرد مفتوح لدى نورس'),
      ),
    );
    await tester.pumpWidget(host(const OrdersPage()));
    await tester.pumpAndSettle();

    // Act
    await takeTheRowThrough(tester, arm: 'حذف الطلبية', confirm: 'حذف');

    // Assert — both rows still there, and still no extra request.
    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(livePageReads(), 1);
  });
}
