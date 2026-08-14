import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customer_detail_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

/// «إدارة الطلبات» as the customer screen actually wires it.
///
/// The section itself is proved in `customer_orders_section_test.dart`. What is left here is the
/// wiring the widget cannot prove about itself: who is shown it, and whether the request behind
/// its numbers is made at all.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCustomerRepository customers;
  late _MockOrderRepository orders;
  late Session session;

  const customer = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    customers = _MockCustomerRepository();
    orders = _MockOrderRepository();
    session = Session();

    when(() => customers.customer(7)).thenAnswer((_) async => const Right(customer));
    when(
      () => orders.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        OrderCounts(byStatus: {'new': 2, 'delivered': 8, 'cancelled': 1}, total: 11),
      ),
    );

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(customers),
          setActivation: SetCustomerActivation(customers),
        ),
      )
      ..registerFactoryParam<CustomerOrderCountsCubit, int, void>(
        (customerId, _) => CustomerOrderCountsCubit(
          customerId: customerId,
          getCounts: GetOrderCounts(orders),
        ),
      );
  });

  tearDown(Injector.reset);

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
      home: CustomerDetailPage(customerId: 7),
    ),
  );

  /// Opens the screen on a real phone-shaped surface.
  ///
  /// **The default test window is 800×600 — wider than a phone and shorter.** ScreenUtil scales
  /// text by the *width* ratio, so on that surface every word is drawn half again too large and
  /// the page runs off the bottom; a `ListView` builds only what is in view, so a finder for
  /// something below the fold reports it missing when it is merely off-screen. Matching the
  /// design size makes the scale factor 1 and asks the question the app is actually asked.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  testWidgets('somebody who may read orders gets the three ways in, counted', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'orders.view']));

    // Act
    await open(tester);

    // Assert
    expect(find.text('إدارة الطلبات'), findsOneWidget);
    expect(find.text('11'), findsOneWidget, reason: 'كل طلبات العميل');
    expect(find.text('2'), findsOneWidget, reason: 'الجارية — the cancelled one is not in it');
    expect(find.text('8'), findsOneWidget, reason: 'المستلمة');
  });

  testWidgets('the numbers are asked about this customer alone', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'orders.view']));

    // Act
    await open(tester);

    // Assert
    verify(() => orders.statusCounts(customerId: 7)).called(1);
  });

  testWidgets('somebody who may not read orders is shown none of it', (tester) async {
    // Arrange — a courtesy on the screen; `orders.view` on the route and on the API is what
    // actually refuses.
    session.adopt(userWith(['customers.view', 'customers.manage']));

    // Act
    await open(tester);

    // Assert
    expect(find.text('إدارة الطلبات'), findsNothing);
    expect(find.text('كل طلبات العميل'), findsNothing);
  });

  testWidgets('and no request is made on their behalf', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view']));

    // Act
    await open(tester);

    // Assert — a call nobody may make is a 403 in the log and a wasted round trip. The Cubit is
    // never created, which is what makes that true rather than merely likely.
    verifyNever(
      () => orders.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    );
  });

  testWidgets('the contact details still arrive when the counts do not', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'orders.view']));
    when(
      () => orders.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'تعذّر الاتصال')));

    // Act
    await open(tester);

    // Assert — the whole reason the numbers have a Cubit of their own: a summary that timed out
    // must not blank a page of details that arrived fine, and the three ways in still open.
    expect(find.text('0913334444'), findsOneWidget);
    expect(find.text('كل طلبات العميل'), findsOneWidget);
  });
}
