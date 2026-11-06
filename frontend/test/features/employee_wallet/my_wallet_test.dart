import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/my_wallet_page.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/my_wallet_row.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EmployeeWalletRepository {}

/// «محفظتي»: الموظف يقرأ محفظته هو، قراءةً فقط. ومدخلُها سطرٌ واحد في الرئيسية وفوق طابور المصمم.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  const credit = EmployeeWalletEntry(
    id: 4,
    type: 'credit',
    typeLabel: 'مستحق',
    direction: 'in',
    amount: '2500.00',
    categoryName: 'رواتب',
  );

  setUpAll(() {
    registerFallbackValue(const EmployeeWalletLedger.mine());
    registerFallbackValue(EmployeeWalletEntryFilter.all);
  });

  void arrange({List<EmployeeWalletEntry> entries = const [credit]}) {
    repository = _MockRepository();

    when(repository.myWallet).thenAnswer(
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
      (_) async => Right(
        Paginated(
          items: entries,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: entries.length),
        ),
      ),
    );

    sl
      ..registerFactory<MyWalletCubit>(() => MyWalletCubit(getWallet: GetMyWallet(repository)))
      ..registerFactoryParam<EmployeeWalletEntriesCubit, EmployeeWalletLedger, void>(
        (ledger, _) => EmployeeWalletEntriesCubit(
          ledger: ledger,
          getEntries: GetEmployeeWalletEntries(repository),
          reverseEntry: ReverseEmployeeWalletEntry(repository),
        ),
      );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// السطر على بطاقة، ومساره إلى «محفظتي» كما في التطبيق.
  Future<void> pumpRow(WidgetTester tester, Widget row) async {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: BlocProvider(
              create: (_) => sl<MyWalletCubit>()..load(),
              child: row,
            ),
          ),
        ),
        GoRoute(path: Routes.myWallet, builder: (context, state) => const MyWalletPage()),
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

  group('شاشة «محفظتي»', () {
    testWidgets('قراءةٌ فقط: لا أزرار ولا إلغاء', (tester) async {
      // Arrange
      arrange();

      // Act
      await pump(tester, const MyWalletPage());

      // Assert
      expect(find.text('محفظتي'), findsOneWidget);
      expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).amount, '1500.00');
      expect(find.byType(AppButton), findsNothing);
      expect(find.text('إلغاء الحركة'), findsNothing);
      expect(find.text('+2,500 د.ل'), findsOneWidget);
    });

    testWidgets('تقرأ سجل صاحبها', (tester) async {
      // Arrange
      arrange();

      // Act
      await pump(tester, const MyWalletPage());

      // Assert
      verify(
        () => repository.entries(
          const EmployeeWalletLedger.mine(),
          page: 1,
          filter: EmployeeWalletEntryFilter.all,
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    testWidgets('محفظة فارغة تقول ذلك', (tester) async {
      // Arrange
      arrange(entries: const []);

      // Act
      await pump(tester, const MyWalletPage());

      // Assert
      expect(find.text('لم تتحرّك محفظتك بعد'), findsOneWidget);
    });
  });

  group('السطر', () {
    testWidgets('على البطاقة: الاسم والرصيد', (tester) async {
      // Arrange
      arrange();

      // Act
      await pumpRow(tester, const MyWalletRow());

      // Assert
      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
    });

    testWidgets('قارئ الشاشة يقرؤه زرّاً واحداً باسمه ورقمه، ويضغطه', (tester) async {
      // Arrange
      final semantics = tester.ensureSemantics();
      arrange();

      // Act
      await pumpRow(tester, const MyWalletRow());

      // Assert
      final node = tester.getSemantics(find.byType(MyWalletRow));
      expect(node, containsSemantics(isButton: true, hasTapAction: true));
      expect(node.label, contains('محفظتي'));
      expect(node.label, contains('1,500 د.ل'));
      semantics.dispose();
    });

    testWidgets('الضغط يفتح «محفظتي»', (tester) async {
      // Arrange
      arrange();
      await pumpRow(tester, const MyWalletRow());

      // Act
      await tester.tap(find.byType(MyWalletRow));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MyWalletPage), findsOneWidget);
    });

    testWidgets('فشل قراءة الرصيد يبقي السطر بلا رقم، ويبقى يفتح «محفظتي»', (tester) async {
      // Arrange
      arrange();
      when(repository.myWallet).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );
      await pumpRow(tester, const MyWalletRow());
      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.textContaining('د.ل'), findsNothing);
      when(repository.myWallet).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '1500.00')),
      );

      // Act
      await tester.tap(find.byType(MyWalletRow));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MyWalletPage), findsOneWidget);
    });

    testWidgets('الرقم الذي قرأته «محفظتي» يعود إلى السطر بلا طلب', (tester) async {
      // Arrange
      arrange();
      await pumpRow(tester, const MyWalletRow());
      when(repository.myWallet).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '900.00')),
      );
      await tester.tap(find.byType(MyWalletRow));
      await tester.pumpAndSettle();

      // Act
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('900 د.ل'), findsOneWidget);
      verify(repository.myWallet).called(2);
    });

    testWidgets('فوق الطابور: السطر نفسه في بطاقته', (tester) async {
      // Arrange
      arrange();

      // Act
      await pumpRow(tester, const MyWalletRow.strip());

      // Assert
      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
    });
  });
}
