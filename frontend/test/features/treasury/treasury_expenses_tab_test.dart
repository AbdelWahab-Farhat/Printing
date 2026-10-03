import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_expenses_cubit.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// «المصاريف» — مصاريف كل الحسابات في تبويبٍ من «المالية». TREASURY-DESIGN §٢١.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockTreasuryRepository repository;
  late Session session;

  const cashBox = TreasuryAccount(
    id: 1,
    name: 'بريمولا قرجي',
    kind: AccountKind.cash,
    kindLabel: 'كاش',
    isDefault: true,
    isActive: true,
    isSystem: false,
    isSpendable: true,
    balance: '320.00',
  );

  const bank = TreasuryAccount(
    id: 2,
    name: 'مصرف الجمهورية',
    kind: AccountKind.bank,
    kindLabel: 'مصرف',
    isDefault: true,
    isActive: true,
    isSystem: false,
    isSpendable: true,
    balance: '900.00',
  );

  const everything = TreasuryAccounts(
    accounts: [cashBox, bank],
    total: '1220.00',
    canViewAll: true,
  );

  TreasuryMovement expense(int id, String amount, String account, String category) =>
      TreasuryMovement.fromJson({
        'id': id,
        'kind': 'expense',
        'kind_label': 'مصروف',
        'direction': 'out',
        'signed_amount': '-$amount',
        'occurred_at': '2026-10-02T10:00:00Z',
        'operation_id': id,
        'account': {'id': 1, 'name': account},
        'category': {'id': 5, 'name': category},
        'is_reversal': false,
        'is_reversible': true,
      });

  Paginated<TreasuryMovement> pageOf(List<TreasuryMovement> items, String total) =>
      Paginated<TreasuryMovement>(
        items: items,
        meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
        extraMeta: {'expenses_total': total},
      );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  void answerExpenses(Paginated<TreasuryMovement> page) {
    when(
      () => repository.expenses(
        page: any(named: 'page'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => Right(page));
  }

  setUp(() async {
    await sl.reset();
    repository = _MockTreasuryRepository();
    session = Session();

    when(
      () => repository.accounts(activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) async => const Right(everything));
    when(() => repository.ownership()).thenAnswer(
      (_) async => const Right(
        TreasuryOwnership(
          totalHeld: '1220.00',
          investors: [],
          investorsTotal: '0.00',
          fundCash: '0.00',
          companyOwn: '1220.00',
        ),
      ),
    );
    when(() => repository.inventoryValue()).thenAnswer(
      (_) async => const Right(
        InventoryValue(total: '0', company: '0', fund: '0', byWarehouse: [], topItems: []),
      ),
    );
    when(
      () => repository.expenseCategories(activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) async => const Right([]));
    answerExpenses(
      pageOf([
        expense(11, '150.00', 'مصرف الجمهورية', 'إيجار'),
        expense(10, '40.00', 'بريمولا قرجي', 'وقود'),
      ], '190.00'),
    );

    sl
      ..registerSingleton<Session>(session)
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => GetTreasuryOwnership(repository))
      ..registerLazySingleton(() => GetInventoryValue(repository))
      ..registerLazySingleton(() => RecordTreasuryOperation(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => GetExpenseCategories(repository))
      ..registerLazySingleton(() => GetTreasuryExpenses(repository))
      ..registerLazySingleton(() => ReverseTreasuryOperation(repository));
  });

  Future<void> openTheTab(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
          home: TreasuryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'المصاريف'));
    await tester.pumpAndSettle();
  }

  group('the tab', () {
    testWidgets('lists every account\'s expenses, each naming its account, under the total', (
      tester,
    ) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));

      // Act
      await openTheTab(tester);

      // Assert
      expect(find.text('مصاريف هذا الشهر'), findsOneWidget);
      expect(find.textContaining('190'), findsOneWidget);
      expect(find.textContaining('من مصرف الجمهورية'), findsOneWidget);
      expect(find.textContaining('من بريمولا قرجي'), findsOneWidget);
    });

    testWidgets('opens on this month', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));
      final now = DateTime.now();

      // Act
      await openTheTab(tester);

      // Assert
      verify(
        () => repository.expenses(
          page: 1,
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1, 0),
        ),
      ).called(1);
    });

    testWidgets('«الكل» asks for every date', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));
      await openTheTab(tester);

      // Act
      await tester.tap(find.text('الكل').first);
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.expenses(page: 1)).called(1);
      expect(find.text('كل المصاريف'), findsOneWidget);
    });

    testWidgets('picking an account narrows the list to it', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));
      await openTheTab(tester);

      // Act
      await tester.tap(find.text('الحساب: الكل'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'مصرف الجمهورية'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.expenses(
          page: 1,
          from: any(named: 'from'),
          to: any(named: 'to'),
          accountId: 2,
        ),
      ).called(1);
      expect(find.text('الحساب: مصرف الجمهورية'), findsOneWidget);
    });

    testWidgets('is not there for somebody who reads only their own accounts', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.record']));
      when(() => repository.accounts(activeOnly: any(named: 'activeOnly'))).thenAnswer(
        (_) async => const Right(
          TreasuryAccounts(accounts: [cashBox], total: '320.00', canViewAll: false),
        ),
      );

      // Act
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) => const MaterialApp(home: TreasuryPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('المصاريف'), findsNothing);
      verifyNever(
        () => repository.expenses(
          page: any(named: 'page'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      );
    });
  });

  group('the period', () {
    test('last month in January is December of the year before', () {
      // Act
      final range = ExpensePeriod.lastMonth.rangeAt(DateTime(2026, 1, 15));

      // Assert
      expect(range?.from, DateTime(2025, 12));
      expect(range?.to, DateTime(2025, 12, 31));
    });

    test('this month ends on its own last day', () {
      // Act
      final range = ExpensePeriod.thisMonth.rangeAt(DateTime(2026, 2, 10));

      // Assert
      expect(range?.from, DateTime(2026, 2));
      expect(range?.to, DateTime(2026, 2, 28));
    });

    test('a reversal re-reads the tab, so the total is the server\'s', () async {
      // Arrange
      when(
        () => repository.reverseOperation(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => const Left(_failure));
      final cubit = TreasuryExpensesCubit(
        getExpenses: GetTreasuryExpenses(repository),
        getCategories: GetExpenseCategories(repository),
        reverseOperation: ReverseTreasuryOperation(repository),
        now: () => DateTime(2026, 10, 15),
      );
      addTearDown(cubit.close);
      await cubit.load();

      // Act
      final failure = await cubit.reverse(
        expense(11, '150.00', 'مصرف الجمهورية', 'إيجار'),
        reason: 'خطأ',
      );

      // Assert — a refused reversal is said, and nothing is re-read
      expect(failure, isNotNull);
      expect(cubit.total, '190.00');
      verify(
        () => repository.expenses(
          page: 1,
          from: DateTime(2026, 10),
          to: DateTime(2026, 10, 31),
        ),
      ).called(1);
    });
  });
}

const _failure = Failure.server(message: 'لا يمكن عكس هذه العملية', statusCode: 422);
