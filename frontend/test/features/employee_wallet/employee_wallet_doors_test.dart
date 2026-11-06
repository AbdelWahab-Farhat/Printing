import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';
import 'package:dayaa/features/auth/usecases/get_current_user.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/employee_wallet_movements_page.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/employee_wallet_page.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_tile.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/my_wallet_row.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:dayaa/features/home/presentation/views/home_page.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/home/repositories/home_repository.dart';
import 'package:dayaa/features/home/usecases/get_home_summary.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/usecases/get_unread_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EmployeeWalletRepository {}

class _MockAuth extends Mock implements AuthRepository {}

class _MockHome extends Mock implements HomeRepository {}

class _MockGetUnreadCount extends Mock implements GetUnreadCount {}

class _MockTickets extends MockCubit<InternalTicketsHomeState>
    implements InternalTicketsHomeCubit {}

/// الأبواب إلى المحفظة: صفُّ صفحة الموظف، و«حركات محافظ الموظفين»، وسطرُ الرئيسية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  const withdrawal = EmployeeWalletEntry(
    id: 5,
    userId: 4,
    user: EmployeeWalletPerson(id: 4, name: 'محمد عز الدين', code: 'E4'),
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '1450.00',
    methodLabel: 'كاش',
    recorderName: 'سارة',
  );

  setUpAll(() {
    registerFallbackValue(const EmployeeWalletLedger.mine());
    registerFallbackValue(EmployeeWalletEntryFilter.all);
    registerFallbackValue(
      const EmployeeMoneyDraft(amount: '1', method: EmployeeWalletMethod.cash),
    );
  });

  void arrange() {
    repository = _MockRepository();

    when(() => repository.wallet(4)).thenAnswer(
      (_) async => const Right(EmployeeWallet(balance: '1500.00')),
    );
    when(
      () => repository.entries(
        any(),
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated(
          items: [withdrawal],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
        ),
      ),
    );

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            const AuthUser(
              id: 1,
              name: 'سارة',
              phone: '0911234567',
              permissions: ['users.wallet.view', 'users.wallet.withdraw'],
            ),
          ),
      )
      ..registerFactoryParam<EmployeeWalletCubit, int, void>(
        (userId, _) => EmployeeWalletCubit(
          userId: userId,
          getWallet: GetEmployeeWallet(repository),
          deposit: DepositToEmployeeWallet(repository),
          credit: CreditEmployeeWallet(repository),
          withdraw: WithdrawFromEmployeeWallet(repository),
          adjust: AdjustEmployeeWallet(repository),
        ),
      )
      ..registerFactoryParam<EmployeeWalletEntriesCubit, EmployeeWalletLedger, void>(
        (ledger, _) => EmployeeWalletEntriesCubit(
          ledger: ledger,
          getEntries: GetEmployeeWalletEntries(repository),
          reverseEntry: ReverseEmployeeWalletEntry(repository),
        ),
      );
  }

  /// [first] على `/`، ومسار المحفظة كما في التطبيق.
  Future<void> pumpRouted(WidgetTester tester, WidgetBuilder first) async {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, _) => first(context)),
        GoRoute(
          path: Routes.employeeWalletPath,
          builder: (context, state) => EmployeeWalletPage(
            userId: int.parse(state.pathParameters['id']!),
            employeeName: state.payload as String?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => sl.reset());

  group('صفّ المحفظة في صفحة الموظف', () {
    Widget tile(BuildContext context) => Scaffold(
      body: BlocProvider(
        create: (_) => sl<EmployeeWalletCubit>(param1: 4)..load(),
        child: const EmployeeWalletTile(userId: 4, employeeName: 'محمد عز الدين'),
      ),
    );

    testWidgets('الضغط يفتح المحفظة', (tester) async {
      // Arrange
      arrange();
      await pumpRouted(tester, tile);

      // Act
      await tester.tap(find.byType(EmployeeWalletTile));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EmployeeWalletPage), findsOneWidget);
    });

    testWidgets('الرصيد بعد سحبٍ يعود إلى الصفّ بلا طلب', (tester) async {
      // Arrange
      arrange();
      when(() => repository.wallet(4)).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '1500.00', canMove: true)),
      );
      when(
        () => repository.withdraw(
          4,
          any(),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Right(EmployeeWalletWrite(entry: withdrawal, balance: '50.00')),
      );
      await pumpRouted(tester, tile);
      await tester.tap(find.byType(EmployeeWalletTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سحب').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '1450');
      await tester.pump();
      await tester.tap(find.text('سحب').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Act
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('50 د.ل'), findsOneWidget);
      verify(() => repository.wallet(4)).called(2);
    });
  });

  group('«حركات محافظ الموظفين»', () {
    testWidgets('كل سطرٍ يقول لمن هو', (tester) async {
      // Arrange
      arrange();

      // Act
      await pumpRouted(tester, (_) => const EmployeeWalletMovementsPage());

      // Assert
      expect(find.text('حركات محافظ الموظفين'), findsOneWidget);
      expect(find.text('محمد عز الدين · كاش'), findsOneWidget);
    });

    testWidgets('تقرأ كل المحافظ، ويُبحث فيها بعد توقّف الكتابة', (tester) async {
      // Arrange
      arrange();
      await pumpRouted(tester, (_) => const EmployeeWalletMovementsPage());

      // Act
      await tester.enterText(find.byType(TextField), 'محمد');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.entries(
          const EmployeeWalletLedger.all(),
          page: 1,
          filter: EmployeeWalletEntryFilter.all,
          search: 'محمد',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    testWidgets('اللمسة تفتح محفظة الموظف باسمه', (tester) async {
      // Arrange
      arrange();
      await pumpRouted(tester, (_) => const EmployeeWalletMovementsPage());

      // Act
      await tester.tap(find.text('محمد عز الدين · كاش'));
      await tester.pumpAndSettle();

      // Assert
      final page = tester.widget<EmployeeWalletPage>(find.byType(EmployeeWalletPage));
      expect(page.employeeName, 'محمد عز الدين');
      verify(() => repository.wallet(4)).called(1);
    });
  });

  group('السطر على الرئيسية', () {
    late _MockAuth auth;
    late _MockHome home;

    Future<void> openHome(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(1290, 2796)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      repository = _MockRepository();
      auth = _MockAuth();
      home = _MockHome();

      when(repository.myWallet).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '1500.00')),
      );
      when(auth.currentUser).thenAnswer(
        (_) async => const Right(AuthUser(id: 1, name: 'سارة علي', phone: '0911234567')),
      );
      when(home.summary).thenAnswer(
        (_) async => const Right(
          HomeSummary(totalOrders: 0, customersCount: 0, dailyOrders: 0, monthlyOrders: 0),
        ),
      );

      final tickets = _MockTickets();
      whenListen(
        tickets,
        const Stream<InternalTicketsHomeState>.empty(),
        initialState: const InternalTicketsHomeState.loading(),
      );
      when(tickets.load).thenAnswer((_) async {});

      final unread = _MockGetUnreadCount();
      when(unread.call).thenAnswer((_) async => const Right(UnreadCount(count: 0)));

      sl
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              const AuthUser(id: 1, name: 'سارة علي', phone: '0911234567', permissions: []),
            ),
        )
        ..registerFactory<HomeCubit>(
          () => HomeCubit(
            getCurrentUser: GetCurrentUser(auth),
            getHomeSummary: GetHomeSummary(home),
          ),
        )
        ..registerFactory<InternalTicketsHomeCubit>(() => tickets)
        ..registerFactory<MyWalletCubit>(() => MyWalletCubit(getWallet: GetMyWallet(repository)));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) => MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: BlocProvider(
                create: (_) => UnreadBadgeCubit(unread),
                child: const HomePage(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('داخل بطاقة الموظف، برصيد صاحبها', (tester) async {
      // Arrange & Act
      await openHome(tester);

      // Assert
      expect(
        find.descendant(of: find.byType(EmployeeCard), matching: find.byType(MyWalletRow)),
        findsOneWidget,
      );
      expect(find.text('1,500 د.ل'), findsOneWidget);
    });

    testWidgets('سحب التحديث يعيد قراءته مع الرئيسية', (tester) async {
      // Arrange
      await openHome(tester);

      // Act
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Assert
      verify(repository.myWallet).called(2);
    });

    testWidgets('فشل قراءته لا يُسقط الرئيسية', (tester) async {
      // Arrange
      await openHome(tester);
      when(repository.myWallet).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );

      // Act
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Assert — الرقمُ الأخير باقٍ، والبطاقةُ في مكانها.
      expect(find.byType(EmployeeCard), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
    });
  });
}
