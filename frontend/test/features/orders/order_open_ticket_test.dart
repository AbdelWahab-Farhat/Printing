import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_deposit_receipt.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/undo_order_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «فتح تذكرة» من الطلبية مباشرةً — طلبُ المالك ٢٠٢٦-١٠-٢٥، كـ«فتح تذكرة فالطلب» في بريمولا.
///
/// كان الطريقُ إليها من بطاقة الموظف في الرئيسية وحدها، ثم اختيارَ الطلبية من ورقتها. الآن ذراعُ
/// «تذاكر الموظفين» نفسُه صار «فتح تذكرة» — «هو نفس الزر، غيّره» — يفتح النموذجَ والطلبيةُ وعميلُها فيه.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  /// ما حمله الذراعُ إلى «تذكرة جديدة» — فما يفعله هو الذهابُ إليها.
  Object? carried;

  const customer = Customer(
    id: 10,
    code: 'A730',
    name: 'حساب تجريبي ٢',
    phone: '0910000002',
    isActive: true,
  );

  final order = Order(
    id: 1320,
    code: '1320',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'استلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من الزبون',
    itemsTotal: '40000.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '40000.00',
    remainingAmount: '40000.00',
    paymentStatusLabel: 'غير مدفوعة',
    customer: customer,
    placedAt: DateTime(2026, 10, 25),
  );

  setUp(() async {
    await Injector.reset();
    carried = null;
    repository = _MockOrderRepository();

    when(() => repository.order(1320)).thenAnswer((_) async => Right(order));

    sl
      // بلا صلاحيةٍ للتذاكر: الداخليةُ لكل موظف. و`orders.view` وحده يُبقي القائمةَ قائمة — مع
      // ذراعين فأكثر لا تنطوي إلى زرٍّ واحد.
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            const AuthUser(id: 1, name: 'فرحات', phone: '0911234567', permissions: ['orders.view']),
          ),
      )
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: GetOrder(repository),
          addDesign: AddOrderDesign(repository),
          reviewDesign: ReviewOrderDesign(repository),
          reinstateOrder: ReinstateOrder(repository),
          unsettleOrder: UnsettleOrder(repository),
          undoOrderDelivery: UndoOrderDelivery(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  });

  tearDown(Injector.reset);

  Widget host() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const OrderDetailPage(orderId: 1320)),
        GoRoute(
          path: Routes.newInternalTicket,
          builder: (context, state) {
            carried = state.extra;

            return const Scaffold(body: Text('تذكرة جديدة'));
          },
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

  Future<void> openTheDial(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
  }

  testWidgets('«فتح تذكرة» took the place of «تذاكر الموظفين» — one arm, not two', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('فتح تذكرة'), findsOneWidget);
    expect(find.text('تذاكر الموظفين'), findsNothing);
  });

  testWidgets('it opens the new ticket with this order and its customer filled in', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('فتح تذكرة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تذكرة جديدة'), findsOneWidget);
    expect(
      carried,
      const InternalTicketSubject(
        orderId: 1320,
        orderCode: '1320',
        customerId: 10,
        customerName: 'حساب تجريبي ٢',
      ),
    );
  });
}
