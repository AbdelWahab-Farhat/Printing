import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/new_internal_ticket_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/views/new_internal_ticket_page.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InternalTicketsRepository {}

class _MockGetOrders extends Mock implements GetOrders {}

class _MockGetCustomers extends Mock implements GetCustomers {}

/// «تذكرة جديدة» تُربط بعميلٍ أو طلبية من النموذج نفسه — طلبُ المالك ٢٠٢٦-١٠-٢٣ — جنباً إلى جنب
/// كنموذج بريمولا: العميلُ وبجانبه الطلبية. ومع العميل لا تُعرض إلا طلبياته، واختيارُ عميلٍ ليست
/// الطلبيةُ المختارة له يُسقطها. وكلٌّ منهما لمن يرى قائمته وحده.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late _MockGetOrders getOrders;
  late _MockGetCustomers getCustomers;

  const amal = Customer(
    id: 4,
    code: 'C4',
    name: 'متجر الأمل',
    phone: '0910000000',
    isActive: true,
  );

  Order order(int id, {required int customerId}) => Order(
    id: id,
    code: '$id',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: customerId,
    cityId: 1,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '110.00',
    remainingAmount: '110.00',
    paymentStatusLabel: 'غير مدفوعة',
  );

  Paginated<T> page<T>(List<T> items) => Paginated<T>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUpAll(() {
    registerFallbackValue(CustomersSort.newest);
    registerFallbackValue(OrdersSort.fallback);
    registerFallbackValue(const InternalTicketDraft(assigneeId: 1, title: 'x', description: 'xyz'));
  });

  Future<void> arrange({
    List<String> permissions = const ['customers.view', 'orders.view'],
    List<Order> orders = const [],
  }) async {
    await Injector.reset();
    repository = _MockRepository();
    getOrders = _MockGetOrders();
    getCustomers = _MockGetCustomers();

    when(() => repository.colleagues()).thenAnswer(
      (_) async => const Right([Colleague(id: 9, name: 'هدى')]),
    );
    when(() => repository.categories()).thenAnswer((_) async => const Right([]));
    // رفضٌ، فتبقى الشاشة — النجاحُ ينتقل إلى المحادثة بموجّهٍ لا يحمله هذا الاختبار.
    when(() => repository.open(any(), images: any(named: 'images'))).thenAnswer(
      (_) async => const Left(Failure.network(message: 'انقطع الاتصال')),
    );
    when(
      () => getCustomers(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        hasOrders: any(named: 'hasOrders'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([amal])));
    when(
      () => getOrders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        readyMessageSent: any(named: 'readyMessageSent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page(orders)));

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(id: 7, name: 'فرحات', phone: '0911234567', permissions: permissions),
          ),
      )
      ..registerFactory<NewInternalTicketCubit>(
        () => NewInternalTicketCubit(
          colleagues: GetColleagues(repository),
          categories: GetInternalCategories(repository),
          open: OpenInternalTicket(repository),
        ),
      )
      ..registerFactory<CustomersCubit>(
        () => CustomersCubit(getCustomers: getCustomers, onlyActive: true),
        instanceName: Injector.activeCustomersCubit,
      )
      ..registerFactoryParam<FilteredOrdersCubit, OrdersFilter, void>(
        (filter, _) => FilteredOrdersCubit(getOrders: getOrders, filter: filter),
      );
  }

  Widget host({InternalTicketSubject? subject}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: NewInternalTicketPage(subject: subject),
    ),
  );

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> pick(WidgetTester tester, String fieldLabel, String choice) async {
    await tester.tap(field(fieldLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice).last);
    await tester.pumpAndSettle();
  }

  /// الزميلُ والعنوانُ والتفاصيل، ثم «فتح التذكرة» — وما ذهب إلى الخادم.
  Future<InternalTicketDraft> submit(WidgetTester tester) async {
    await pick(tester, 'مع مَن؟', 'هدى');
    await tester.enterText(field('العنوان'), 'الأكياس');
    await tester.enterText(field('التفاصيل'), 'هل وصلت من المطبعة؟');
    await tester.pump();
    await tester.ensureVisible(find.text('فتح التذكرة'));
    await tester.tap(find.text('فتح التذكرة'));
    await tester.pumpAndSettle();
    // رسالةُ الرفض تغيب بمؤقّتها، ولا يبقى مؤقّتٌ بعد الاختبار.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    return verify(
          () => repository.open(captureAny(), images: any(named: 'images')),
        ).captured.single
        as InternalTicketDraft;
  }

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 1400)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  tearDown(Injector.reset);

  testWidgets('with both lists readable the form offers a customer and an order', (tester) async {
    // Arrange
    await arrange();

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(field('العميل'), findsOneWidget);
    expect(field('الطلبية'), findsOneWidget);
  });

  testWidgets('somebody who may not read customers or orders is offered neither', (tester) async {
    // Arrange
    await arrange(permissions: const []);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(field('العميل'), findsNothing);
    expect(field('الطلبية'), findsNothing);
  });

  testWidgets('opened from an order, the order is filled in and travels with the ticket', (
    tester,
  ) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host(subject: const InternalTicketSubject(orderId: 55, orderCode: '55')));
    await tester.pumpAndSettle();

    // Act
    final draft = await submit(tester);

    // Assert
    expect(find.widgetWithText(TextField, '55'), findsOneWidget);
    expect(draft.orderId, 55);
    expect(draft.customerId, isNull);
  });

  testWidgets('a customer picked from the sheet travels with the ticket', (tester) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await pick(tester, 'العميل', 'متجر الأمل');
    final draft = await submit(tester);

    // Assert
    expect(draft.customerId, 4);
    expect(draft.orderId, isNull);
  });

  testWidgets('with a customer named, the order sheet lists that customer\'s orders only', (
    tester,
  ) async {
    // Arrange
    await arrange(orders: [order(77, customerId: 4)]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await pick(tester, 'العميل', 'متجر الأمل');

    // Act
    await pick(tester, 'الطلبية', '77');
    final draft = await submit(tester);

    // Assert
    verify(
      () => getOrders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        readyMessageSent: any(named: 'readyMessageSent'),
        sort: any(named: 'sort'),
        customerId: 4,
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(greaterThan(0));
    expect(draft.customerId, 4);
    expect(draft.orderId, 77);
  });

  testWidgets('a customer the chosen order does not belong to drops that order', (tester) async {
    // Arrange
    await arrange(orders: [order(88, customerId: 10)]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await pick(tester, 'الطلبية', '88');

    // Act
    await pick(tester, 'العميل', 'متجر الأمل');
    final draft = await submit(tester);

    // Assert
    expect(draft.customerId, 4);
    expect(draft.orderId, isNull);
  });

  testWidgets('the clear button takes a picked customer off again', (tester) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await pick(tester, 'العميل', 'متجر الأمل');

    // Act
    await tester.tap(find.byTooltip('إزالة العميل'));
    await tester.pumpAndSettle();
    final draft = await submit(tester);

    // Assert
    expect(draft.customerId, isNull);
  });
}

