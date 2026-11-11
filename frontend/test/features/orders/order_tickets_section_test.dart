import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_for_order.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_flow.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/order_ticket.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_tickets_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_tickets_section.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order_tickets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «التذاكر المرتبطة» في صفحة الطلبية — طلبُ المالك ٢٠٢٦-١٠-٢٨، كقسمها في بريمولا: كلُّ الأنواع
/// بنوعها بجانبها، المفتوحةُ والمغلقة، و«إضافة تذكرة» في الرأس.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late GoRouter router;

  /// المسارُ الذي فُتح من القسم، وما حُمل إليه.
  String? opened;
  Object? carried;

  const customer = Customer(
    id: 10,
    code: 'A730',
    name: 'مارفيلا',
    phone: '0910000002',
    isActive: true,
  );

  const order = Order(
    id: 1470,
    code: '1470',
    status: OrderStatus.printing,
    statusLabel: 'قيد الطباعة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '1360.00',
    designFee: '0.00',
    deliveryPrice: '30.00',
    discount: '0.00',
    grandTotal: '1390.00',
    remainingAmount: '1390.00',
    paymentStatusLabel: 'غير مدفوعة',
    customer: customer,
  );

  const staff = OrderTicket(
    kind: OrderTicketKind.internal,
    kindLabel: 'موظفين',
    id: 24,
    code: 'T24',
    title: 'الطلبية متأخرة في المطبعة',
    status: 'in_progress',
    statusLabel: 'قيد المعالجة',
    isOpen: true,
  );

  const design = OrderTicket(
    kind: OrderTicketKind.design,
    kindLabel: 'تصميم',
    id: 6,
    code: 'D6',
    title: 'تعديل الشعار',
    status: 'changes_requested',
    statusLabel: 'تعديل مطلوب',
    isOpen: true,
  );

  const support = OrderTicket(
    kind: OrderTicketKind.support,
    kindLabel: 'عميل',
    id: 31,
    title: 'متى تصل الأكياس؟',
    status: 'closed',
    statusLabel: 'مغلقة',
  );

  setUp(() async {
    await Injector.reset();
    opened = null;
    carried = null;
    repository = _MockOrderRepository();

    sl.registerFactory<OrderTicketsCubit>(
      () => OrderTicketsCubit(getTickets: GetOrderTickets(repository)),
    );
  });

  tearDown(Injector.reset);

  Widget destination(GoRouterState state) {
    opened = state.uri.toString();
    carried = state.extra;

    return const Scaffold(body: Text('شاشة التذكرة'));
  }

  Widget host({Order shown = order}) {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(child: OrderTicketsSection(order: shown)),
          ),
        ),
        GoRoute(path: Routes.newInternalTicket, builder: (context, state) => destination(state)),
        GoRoute(path: Routes.designTicketForm, builder: (context, state) => destination(state)),
        GoRoute(path: Routes.internalTicketPath, builder: (context, state) => destination(state)),
        GoRoute(path: Routes.designTicketDetailPath, builder: (context, state) => destination(state)),
        GoRoute(path: '/support/tickets/:id', builder: (context, state) => destination(state)),
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

  testWidgets('every kind is listed with its kind beside it, closed ones included', (tester) async {
    // Arrange
    when(() => repository.orderTickets(1470))
        .thenAnswer((_) async => const Right([staff, design, support]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('التذاكر المرتبطة'), findsOneWidget);
    expect(find.text('T24'), findsOneWidget);
    expect(find.text('موظفين'), findsOneWidget);
    expect(find.text('D6'), findsOneWidget);
    expect(find.text('تصميم'), findsOneWidget);
    expect(find.text('تعديل مطلوب'), findsOneWidget);
    // تذكرةُ العميل بلا كود: تُعرف برقمها.
    expect(find.text('#31'), findsOneWidget);
    expect(find.text('عميل'), findsOneWidget);
    expect(find.text('مغلقة'), findsOneWidget);
    expect(find.text('متى تصل الأكياس؟'), findsOneWidget);
  });

  testWidgets('no tickets says so, under the button that adds one', (tester) async {
    // Arrange
    when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد تذاكر مرتبطة بهذه الطلبية'), findsOneWidget);
    expect(find.text('إضافة تذكرة'), findsOneWidget);
  });

  testWidgets('each row opens the screen of its own kind', (tester) async {
    // Arrange
    when(() => repository.orderTickets(1470))
        .thenAnswer((_) async => const Right([staff, design, support]));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final visited = <String?>[];

    // Act
    for (final label in ['T24', 'D6', '#31']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      visited.add(opened);
      router.pop();
      await tester.pumpAndSettle();
    }

    // Assert
    expect(visited, ['/internal-tickets/24', '/design-tickets/6', '/support/tickets/31']);
  });

  testWidgets('«إضافة تذكرة» opens the form on this order, and the list is read again after', (tester) async {
    // Arrange
    when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([]));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إضافة تذكرة'));
    await tester.pumpAndSettle();
    when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([staff]));
    router.pop();
    await tester.pumpAndSettle();

    // Assert
    expect(opened, Routes.newInternalTicket);
    expect(carried, isA<InternalTicketSubject>());
    final subject = carried! as InternalTicketSubject;
    expect(subject.orderId, 1470);
    expect(subject.customerId, 10);
    expect(find.text('T24'), findsOneWidget);
  });

  group('a design ticket from the order (PRINT-COLORS.md §10)', () {
    void signInWith(List<String> permissions) {
      final session = Session()
        ..adopt(AuthUser(id: 1, name: 'فرحات', phone: '0911234567', permissions: permissions));
      sl.registerSingleton<Session>(session);
    }

    // Still taking artwork, and printed here.
    final open = order.copyWith(
      status: OrderStatus.readyToPrint,
      designsAreEditable: true,
      productionFlow: OrderFlow.standard,
    );

    testWidgets('is offered beside the internal ticket, and carries the order', (tester) async {
      // Arrange
      signInWith(['design_tickets.manage']);
      when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([]));
      await tester.pumpWidget(host(shown: open));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إضافة تذكرة'));
      await tester.pumpAndSettle();
      expect(find.text('تذكرة داخلية'), findsOneWidget);
      await tester.tap(find.text('تذكرة تصميم'));
      await tester.pumpAndSettle();

      // Assert
      expect(opened, Routes.designTicketForm);
      final subject = carried! as DesignTicketForOrder;
      expect(subject.orderId, 1470);
      expect(subject.customer.id, 10);
      expect(subject.colorsRequired, isTrue);
    });

    testWidgets('is not offered once the order no longer takes artwork', (tester) async {
      // Arrange — at the press: the design could not be added to it any more.
      signInWith(['design_tickets.manage']);
      when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إضافة تذكرة'));
      await tester.pumpAndSettle();

      // Assert — straight to the internal ticket, as before.
      expect(opened, Routes.newInternalTicket);
    });

    testWidgets('is not offered to somebody who may not raise one', (tester) async {
      // Arrange
      signInWith(['orders.view']);
      when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([]));
      await tester.pumpWidget(host(shown: open));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إضافة تذكرة'));
      await tester.pumpAndSettle();

      // Assert
      expect(opened, Routes.newInternalTicket);
    });
  });

  testWidgets('a failed read offers to try again', (tester) async {
    // Arrange
    when(() => repository.orderTickets(1470))
        .thenAnswer((_) async => const Left(Failure.network(message: 'لا اتصال')));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    when(() => repository.orderTickets(1470)).thenAnswer((_) async => const Right([design]));

    // Act
    await tester.tap(find.text('تعذّر تحميل التذاكر — إعادة المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('D6'), findsOneWidget);
  });
}
