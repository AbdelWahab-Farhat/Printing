import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_review_queue_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_settlement_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/payment_settlement_page.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// «مراجعة وتسوية الدفعات» — صفحةٌ واحدة تُفتح من «حالات الدفع» في الرئيسية (٢٠٢٦-١٠-٠٨).
///
/// **تبويبان، وعدّاد كلٍّ منهما في اسمه**: «تحتاج مراجعة» لمن يراجع، و«تحتاج تسوية» لمن يسوّي —
/// وفي الثاني «بانتظار التسوية» و«مسوّاة» خلف مفتاحٍ واحد. والفلاتر فوق الصفوف وتمرّ معها: البحث،
/// وتحته «الكل · اليوم · هذا الأسبوع · هذا الشهر» على «الكل»، و«من» / «إلى» والحساب في الفلتر المتقدّم.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderPaymentRepository repository;

  AuthUser userWith(List<String> permissions) => AuthUser(
    id: 1,
    name: 'فرحات',
    phone: '0911234567',
    permissions: permissions,
  );

  OrderPayment payment(int id) => OrderPayment(
    id: id,
    orderId: 7,
    type: OrderPaymentType.payment,
    typeLabel: 'دفعة',
    amount: '100.00',
    method: PaymentMethod.cash,
    methodLabel: 'كاش',
  );

  Paginated<OrderPayment> pageOf(List<OrderPayment> items) => Paginated<OrderPayment>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUpAll(() {
    registerFallbackValue(SettlementState.pending);
    registerFallbackValue(OrderPaymentType.payment);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    await Injector.reset();
    repository = _MockOrderPaymentRepository();
    when(
      () => repository.reviewQueue(
        page: any(named: 'page'),
        type: any(named: 'type'),
        accountId: any(named: 'accountId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Right(pageOf([payment(1), payment(2)])));
    when(
      () => repository.settlementQueue(
        page: any(named: 'page'),
        state: any(named: 'state'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        accountId: any(named: 'accountId'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((invocation) async {
      final state = invocation.namedArguments[#state] as SettlementState;

      return Right(pageOf(state == SettlementState.pending ? [payment(3)] : const []));
    });
    when(() => repository.settlementAccounts()).thenAnswer(
      (_) async => const Right(
        SettlementAccounts(
          sources: [SettlementAccount(id: 9, name: 'النورس')],
          destinations: [SettlementAccount(id: 2, name: 'المصرف')],
        ),
      ),
    );
    sl
      ..registerFactory<PaymentReviewQueueCubit>(
        () => PaymentReviewQueueCubit(
          getQueue: GetPaymentReviewQueue(repository),
          reviewPayment: ReviewOrderPayment(repository),
        ),
      )
      ..registerFactoryParam<PaymentSettlementCubit, SettlementState, void>(
        (tab, _) => PaymentSettlementCubit(
          getQueue: GetPaymentSettlementQueue(repository),
          getAccounts: GetSettlementAccounts(repository),
          settlePayments: SettleOrderPayments(repository),
          unsettlePayment: UnsettleOrderPayment(repository),
          tab: tab,
        ),
      );
  });

  tearDown(Injector.reset);

  Future<void> open(WidgetTester tester, List<String> permissions) async {
    sl.registerSingleton<Session>(Session()..adopt(userWith(permissions)));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PaymentSettlementPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const both = ['orders.payments.review', 'orders.payments.settle'];

  group('the tabs', () {
    testWidgets('somebody who reviews and settles gets two, review first, each with its count', (tester) async {
      // Act
      await open(tester, both);

      // Assert — من اليمين: المراجعة ثم التسوية، والعدد في الاسم.
      expect(find.text('مراجعة وتسوية الدفعات'), findsOneWidget);
      final review = tester.getCenter(find.widgetWithText(Tab, 'تحتاج مراجعة (2)'));
      final settle = tester.getCenter(find.widgetWithText(Tab, 'تحتاج تسوية (1)'));
      expect(review.dx, greaterThan(settle.dx));
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('no counter line sits under the filters any more', (tester) async {
      // Act
      await open(tester, both);

      // Assert
      expect(find.textContaining('بانتظار المراجعة:'), findsNothing);
      expect(find.textContaining('بانتظار التسوية:'), findsNothing);
    });

    testWidgets('somebody who only reviews gets the list alone, with no tab bar', (tester) async {
      // Act
      await open(tester, ['orders.payments.review']);

      // Assert
      expect(find.text('مراجعة وتسوية الدفعات'), findsOneWidget);
      expect(find.byType(Tab), findsNothing);
      expect(find.byType(SearchField), findsOneWidget);
    });
  });

  group('the filters', () {
    testWidgets('search first, then the period chips — «الكل» first and picked; «من – إلى» is no chip', (
      tester,
    ) async {
      // Act
      await open(tester, both);

      // Assert
      expect(find.byType(SearchField), findsOneWidget);
      final all = find.widgetWithText(FilterOptionChip, 'الكل');
      expect(tester.widget<FilterOptionChip>(all).isSelected, isTrue);
      expect(tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, 'اليوم')).isSelected, isFalse);
      // من اليمين: «الكل» أوّلاً.
      expect(tester.getCenter(all).dx, greaterThan(tester.getCenter(find.widgetWithText(FilterOptionChip, 'اليوم')).dx));
      expect(find.text('من – إلى'), findsNothing);
      verify(() => repository.reviewQueue(page: 1)).called(1);
    });

    testWidgets('the review tab\'s advanced filter holds «من», «إلى» and the type — no account', (tester) async {
      // Arrange
      await open(tester, both);

      // Act
      await tester.tap(find.byKey(const ValueKey('advanced-filter')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('من'), findsOneWidget);
      expect(find.text('إلى'), findsOneWidget);
      expect(find.text('النوع'), findsOneWidget);
      expect(find.text('الحساب'), findsNothing);
      expect(find.text('تطبيق'), findsOneWidget);
    });
  });

  group('the settlement tab', () {
    testWidgets('waiting and settled sit behind one switch, waiting first', (tester) async {
      // Arrange
      await open(tester, both);
      await tester.tap(find.widgetWithText(Tab, 'تحتاج تسوية (1)'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('مسوّاة'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('بانتظار التسوية'), findsWidgets);
      verify(() => repository.settlementQueue(page: 1, state: SettlementState.settled)).called(1);
      expect(find.text('لا دفعات مسوّاة في هذه الفترة'), findsOneWidget);
    });

    testWidgets('its advanced filter holds «من», «إلى» and the account — no type', (tester) async {
      // Arrange
      await open(tester, ['orders.payments.settle']);

      // Act
      await tester.tap(find.byKey(const ValueKey('advanced-filter')).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('من'), findsOneWidget);
      expect(find.text('إلى'), findsOneWidget);
      expect(find.text('الحساب'), findsOneWidget);
      expect(find.text('النوع'), findsNothing);
    });
  });

  group('the route', () {
    Future<String?> redirectFor(WidgetTester tester, List<String> permissions) async {
      sl.registerSingleton<Session>(Session()..adopt(userWith(permissions)));
      await tester.pumpWidget(const SizedBox());

      final location = Uri.parse(Routes.paymentSettlement);
      final configuration = AppRouter.instance.configuration;
      final route = configuration.findMatch(location).matches.last.route as GoRoute;

      return route.redirect!(
        tester.element(find.byType(SizedBox)),
        GoRouterState(
          configuration,
          uri: location,
          matchedLocation: Routes.paymentSettlement,
          fullPath: Routes.paymentSettlement,
          pathParameters: const {},
          pageKey: const ValueKey('payment-settlement'),
        ),
      );
    }

    testWidgets('a reviewer who cannot settle goes through', (tester) async {
      // Act
      final target = await redirectFor(tester, ['orders.payments.review']);

      // Assert
      expect(target, isNull);
    });

    testWidgets('a settler who cannot review goes through', (tester) async {
      // Act
      final target = await redirectFor(tester, ['orders.payments.settle']);

      // Assert
      expect(target, isNull);
    });

    testWidgets('somebody holding neither is sent home', (tester) async {
      // Act
      final target = await redirectFor(tester, ['orders.view']);

      // Assert
      expect(target, Routes.home);
    });
  });
}
