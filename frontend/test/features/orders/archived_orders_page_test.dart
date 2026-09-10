import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/archived_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/archived_orders_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_filter_button.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_sort_button.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_archived_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// أرشيف الطلبيات on screen.
///
/// **What is worth proving is that it really is the orders screen.** §٨ chose to mirror
/// `OrdersPage` rather than reuse `FilteredOrdersPage`, because `OrdersFilter` cannot express
/// «نفس الفلاتر» — it has six fields, no urgency, no city and no search. So the search box, the
/// sort button and the filter button with its own counts all have to be here, and the rows have
/// to be the same [OrderCard] the live list draws.
///
/// **And that a trashed row offers no move.** Nothing on this screen suppresses that: a deleted
/// order arrives with no `available_transitions`, so the shared card draws none — see §٦, where
/// the resource dropping the key is called correctness rather than economy. The test states it
/// anyway, because it is the property a future change to [OrderCard] could break from a
/// distance.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  setUpAll(() => registerFallbackValue(OrdersSort.newest));

  late _MockOrderRepository repository;

  Order archived({int id = 7}) => Order(
    id: id,
    code: '$id',
    status: OrderStatus.cancelled,
    statusLabel: 'إلغاء تام',
    isFinal: true,
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
    // What makes it an archive row — and the reason the shop's own list refuses it.
    deletedAt: DateTime(2026, 9, 10),
  );

  Future<void> arrange(List<Order> rows) async {
    await Injector.reset();

    repository = _MockOrderRepository();

    when(
      () => repository.archivedStatusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer(
      (_) async => const Right(OrderCounts(byStatus: {'cancelled': 1}, total: 1)),
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
    ).thenAnswer(
      (_) async => Right(
        Paginated<Order>(
          items: rows,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: rows.length),
        ),
      ),
    );

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            const AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: ['orders.view', 'orders.archive.view'],
            ),
          ),
      )
      ..registerFactory<ArchivedOrdersCubit>(
        () => ArchivedOrdersCubit(
          getOrders: GetArchivedOrders(repository),
          getCounts: GetArchivedOrderCounts(repository),
        ),
      );
  }

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ArchivedOrdersPage(),
    ),
  );

  tearDown(Injector.reset);

  testWidgets('it is the orders screen: the same search, sort and filter', (tester) async {
    // Arrange
    await arrange([archived()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the same three controls, the same widgets, in the same row.
    expect(find.text('أرشيف الطلبيات'), findsOneWidget);
    expect(find.text('رقم الطلبية · كود العميل · رقم الهاتف'), findsOneWidget);
    expect(find.byType(OrderSortButton), findsOneWidget);
    expect(find.byType(OrderFilterButton), findsOneWidget);
  });

  testWidgets('the rows are the same card the live list draws', (tester) async {
    // Arrange
    await arrange([archived(), archived(id: 9)]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(OrderCard), findsNWidgets(2));
  });

  testWidgets('a trashed row offers no status move, because none arrived with it', (
    tester,
  ) async {
    // Arrange — `availableTransitions` defaults to empty and the server sends no such key for
    // an archived order. The card reads that list and nothing else.
    await arrange([archived()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(
      tester.widget<OrderCard>(find.byType(OrderCard)).order.availableTransitions,
      isEmpty,
    );
  });

  testWidgets('an empty archive says so in its own words', (tester) async {
    // Arrange — «لا توجد طلبيات محذوفة», not الطلبيات's «لا توجد طلبيات في هذه القائمة»: an
    // empty archive is good news, and a sentence about a queue would read as a fault.
    await arrange(const []);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد طلبيات محذوفة'), findsOneWidget);
  });
}
