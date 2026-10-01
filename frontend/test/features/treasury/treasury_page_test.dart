import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_cubit.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// «الحسابات والكاش» — المجموع، وزرّان لما لا يقدّمه أي حساب، والإجابات الثلاث في تبويبات.
/// TREASURY-DESIGN §٩.
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

  const everything = TreasuryAccounts(accounts: [cashBox], total: '320.00', canViewAll: true);

  const ownership = TreasuryOwnership(
    totalHeld: '320.00',
    investors: [InvestorHolding(id: 7, name: 'بادي 1', capital: '4698.00', profit: '0.00')],
    investorsTotal: '4698.00',
    fundCash: '3000.00',
    companyOwn: '-7378.00',
  );

  const inventory = InventoryValue(
    total: '23278.41',
    company: '12058.46',
    fund: '11219.95',
    byWarehouse: [ValueLine(name: 'المخزن الرئيسي', value: '23278.41')],
    topItems: [],
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await sl.reset();
    repository = _MockTreasuryRepository();
    session = Session();

    when(
      () => repository.accounts(activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) async => const Right(everything));
    when(() => repository.ownership()).thenAnswer((_) async => const Right(ownership));
    when(() => repository.inventoryValue()).thenAnswer((_) async => const Right(inventory));
    when(
      () => repository.expenseCategories(activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) async => const Right([]));

    sl
      ..registerSingleton<Session>(session)
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => GetTreasuryOwnership(repository))
      ..registerLazySingleton(() => GetInventoryValue(repository))
      ..registerLazySingleton(() => RecordTreasuryOperation(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => GetExpenseCategories(repository));
  });

  Future<void> openThePage(WidgetTester tester) async {
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
  }

  group('the buttons', () {
    testWidgets('only what no account offers sits here — a new account and a new expense', (
      tester,
    ) async {
      // Arrange
      session.adopt(userWith(['treasury.view', 'treasury.record', 'treasury.manage']));

      // Act
      await openThePage(tester);

      // Assert — the deposit, the transfer and the rest live on the account itself.
      expect(find.widgetWithText(AppButton, 'حساب جديد'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'مصروف جديد'), findsOneWidget);
      expect(find.byType(AppSpeedDial), findsNothing);
      expect(find.text('إيداع'), findsNothing);
      expect(find.text('تحويل'), findsNothing);
    });

    testWidgets('each button shows only to whom may use it', (tester) async {
      // Arrange — may record an expense, may not open an account.
      session.adopt(userWith(['treasury.view', 'treasury.record']));

      // Act
      await openThePage(tester);

      // Assert
      expect(find.widgetWithText(AppButton, 'مصروف جديد'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'حساب جديد'), findsNothing);
    });

    testWidgets('«مصروف جديد» opens the expense form', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.view', 'treasury.record']));
      await openThePage(tester);

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'مصروف جديد'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(AppButton, 'تسجيل مصروف'), findsOneWidget);
    });
  });

  group('the tabs', () {
    testWidgets('the page opens on the accounts, with the other two answers one tap away', (
      tester,
    ) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));

      // Act
      await openThePage(tester);

      // Assert
      expect(find.widgetWithText(Tab, 'الحسابات'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'لمن المال'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'المخزون'), findsOneWidget);
      expect(find.text('بريمولا قرجي'), findsOneWidget);
      expect(find.text('بادي 1'), findsNothing);
    });

    testWidgets('a tab shows its answer in place of the accounts', (tester) async {
      // Arrange
      session.adopt(userWith(['treasury.view']));
      await openThePage(tester);

      // Act
      await tester.tap(find.widgetWithText(Tab, 'لمن المال'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('بادي 1'), findsOneWidget);
      expect(find.text('مال الشركة نفسها'), findsOneWidget);
      expect(find.text('بريمولا قرجي'), findsNothing);
    });

    testWidgets('somebody reading only their own accounts gets the list, no tabs, no buttons', (
      tester,
    ) async {
      // Arrange
      session.adopt(userWith(['treasury.record', 'treasury.manage']));
      when(() => repository.accounts(activeOnly: any(named: 'activeOnly'))).thenAnswer(
        (_) async => const Right(
          TreasuryAccounts(accounts: [cashBox], total: '320.00', canViewAll: false),
        ),
      );

      // Act
      await openThePage(tester);

      // Assert
      expect(find.text('ما في حساباتك'), findsOneWidget);
      expect(find.text('بريمولا قرجي'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('a reload', () {
    test('keeps the two answers standing until the new ones arrive', () async {
      // Arrange — a page already loaded, so its tabs are on the screen.
      final cubit = TreasuryCubit(
        getAccounts: GetTreasuryAccounts(repository),
        getOwnership: GetTreasuryOwnership(repository),
        getInventoryValue: GetInventoryValue(repository),
        recordOperation: RecordTreasuryOperation(repository),
        saveAccount: SaveTreasuryAccount(repository),
      );
      addTearDown(cubit.close);
      await cubit.load();
      final seen = <TreasuryState>[];
      final subscription = cubit.stream.listen(seen.add);
      addTearDown(subscription.cancel);

      // Act
      await cubit.load();

      // Assert — no state between the two loads drops a tab, so the one open stays open.
      expect(seen, isNotEmpty);
      for (final state in seen) {
        expect(state, isA<TreasuryLoaded>());
        expect((state as TreasuryLoaded).ownership, isNotNull);
        expect(state.inventory, isNotNull);
      }
    });
  });
}
