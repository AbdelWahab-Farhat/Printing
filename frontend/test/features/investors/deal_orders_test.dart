import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_orders_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/deal_orders_page.dart';
import 'package:dayaa/features/investors/presentation/widgets/deal_order_card.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «طلبيات الصفقة» — the list that says which orders sold a deal's goods and what each earned.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorRepository {}

void main() {
  late _MockRepository repository;

  DealOrder orderWith({
    int id = 7,
    String profit = '3000.00',
    String? investorsShare = '1500.00',
    String? companyShare = '1500.00',
    bool isPosted = true,
    String status = 'delivered',
    String statusLabel = 'تم الاستلام',
  }) => DealOrder(
    orderId: id,
    code: '$id',
    status: status,
    statusLabel: statusLabel,
    customerName: 'مطبعة النور',
    grandTotal: '15000.00',
    quantity: '1000.000',
    materialCost: '2000.00',
    revenue: '5000.00',
    conversionCost: '0.00',
    profit: profit,
    investorsShare: investorsShare,
    companyShare: companyShare,
    isPosted: isPosted,
  );

  Paginated<DealOrder> page(List<DealOrder> items, {int lastPage = 1}) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: lastPage, total: items.length),
  );

  Widget host(DealOrder order) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: DealOrderCard(order: order)),
    ),
  );

  /// The whole screen inside a router, with a stub standing where the order's own screen would
  /// open — the row is a door, and this is how the test sees which one it opened.
  Widget screen(List<DealOrder> orders) {
    when(
      () => repository.dealOrders(any(), page: any(named: 'page'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => Right(page(orders)));

    sl.registerFactory<DealOrdersCubit>(
      () => DealOrdersCubit(getOrders: GetDealOrders(repository)),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DealOrdersPage(dealId: 42, dealCode: 'D26'),
        ),
        GoRoute(
          path: Routes.orderDetailPath,
          builder: (context, state) => Scaffold(
            body: Center(child: Text('طلبية رقم ${state.pathParameters['id']}')),
          ),
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

  setUp(() async {
    await Injector.reset();
    repository = _MockRepository();
  });

  tearDown(Injector.reset);

  group('the list', () {
    test('asks for the deal it was opened on, and keeps asking for that one', () async {
      // Arrange — the deal is set once, when the screen opens; page two must not lose it.
      when(
        () => repository.dealOrders(any(), page: any(named: 'page'), perPage: any(named: 'perPage')),
      ).thenAnswer((_) async => Right(page([orderWith()], lastPage: 2)));

      final cubit = DealOrdersCubit(getOrders: GetDealOrders(repository));

      // Act
      await cubit.open(42);
      await cubit.loadMore();

      // Assert
      verify(() => repository.dealOrders(42, page: 1, perPage: 20)).called(1);
      verify(() => repository.dealOrders(42, page: 2, perPage: 20)).called(1);
    });
  });

  group('a row', () {
    testWidgets('opens the order it stands for', (tester) async {
      // Arrange — one order sold this deal's goods.
      await tester.pumpWidget(screen([orderWith(id: 1209)]));
      await tester.pumpAndSettle();

      // Act — the whole card is the door, not a button on it.
      await tester.tap(find.text('طلبية 1209'));
      await tester.pumpAndSettle();

      // Assert — the order's own screen, for that order.
      expect(find.text('طلبية رقم 1209'), findsOneWidget);
    });

    testWidgets('shows what the deal earned beside what the investors were paid', (tester) async {
      // Arrange
      await tester.pumpWidget(host(orderWith()));

      // Act
      await tester.pump();

      // Assert — both figures, and the order they belong to.
      expect(find.text('طلبية 7'), findsOneWidget);
      expect(find.text('ربح الصفقة'), findsOneWidget);
      expect(find.text('3,000 د.ل'), findsOneWidget);
      expect(find.text('نصيب المستثمرين'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
    });

    testWidgets('says nothing about a share nobody has been paid yet', (tester) async {
      // Arrange — the goods left the shelf at «جاهزة للطباعة» and the parcel is on the road.
      await tester.pumpWidget(
        host(
          orderWith(
            investorsShare: null,
            companyShare: null,
            isPosted: false,
            status: 'out_for_delivery',
            statusLabel: 'جاري التوصيل',
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — the deal's own profit stands, and the second figure is absent rather than
      // drawn as 0.00, which would say the order broke even. The pill says why.
      expect(find.text('ربح الصفقة'), findsOneWidget);
      expect(find.text('نصيب المستثمرين'), findsNothing);
      expect(find.text('0 د.ل'), findsNothing);
      expect(find.text('جاري التوصيل'), findsOneWidget);
    });

    testWidgets('a losing order is labelled a loss and its number carries no sign', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(orderWith(profit: '-500.00', investorsShare: '-250.00', companyShare: '-250.00')),
      );

      // Act
      await tester.pump();

      // Assert — the label carries the sign, so a minus is never drawn twice.
      expect(find.text('خسارة الصفقة'), findsOneWidget);
      expect(find.text('خسارة المستثمرين'), findsOneWidget);
      expect(find.text('500 د.ل'), findsOneWidget);
      expect(find.text('250 د.ل'), findsOneWidget);
      expect(find.text('-500 د.ل'), findsNothing);
    });
  });
}
