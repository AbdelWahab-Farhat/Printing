import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_account_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// صفحة الحساب: الرصيد، ثم السجلّ مقصوراً بفلتر «الكل · الطلبيات · المصاريف». TREASURY-DESIGN §٩.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockTreasuryRepository repository;

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

  const payment = TreasuryMovement(
    id: 1,
    kind: 'payment',
    kindLabel: 'دفعة زبون',
    isIn: true,
    signedAmount: '320.00',
    balanceAfter: '320.00',
    isReversal: false,
    orderId: 1290,
  );

  const rent = TreasuryMovement(
    id: 2,
    kind: 'expense',
    kindLabel: 'مصروف',
    isIn: false,
    signedAmount: '-50.00',
    balanceAfter: '270.00',
    isReversal: false,
    categoryName: 'إيجار',
  );

  Paginated<TreasuryMovement> pageOf(List<TreasuryMovement> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUpAll(() => registerFallbackValue(MovementFilter.all));

  setUp(() async {
    await sl.reset();
    repository = _MockTreasuryRepository();
    final session = Session()
      ..adopt(
        const AuthUser(
          id: 1,
          name: 'عبدالوهاب',
          phone: '0911234567',
          permissions: ['treasury.view'],
        ),
      );

    when(
      () => repository.account(1),
    ).thenAnswer((_) async => const Right(TreasuryAccountDetail(account: cashBox)));
    when(
      () => repository.movements(
        1,
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Right(pageOf(const [payment, rent])));
    when(
      () => repository.movements(
        1,
        page: any(named: 'page'),
        filter: MovementFilter.expenses,
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Right(pageOf(const [rent])));

    sl
      ..registerSingleton<Session>(session)
      ..registerLazySingleton(() => GetTreasuryAccount(repository))
      // رأسُ الصفحة يسأل عن الحسابات حين يُختار «تحويل» — يُسجَّل ولا يُطلب هنا.
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => GetAccountMovements(repository))
      ..registerLazySingleton(() => RecordTreasuryOperation(repository))
      ..registerLazySingleton(() => ReverseTreasuryOperation(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository));
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
          home: TreasuryAccountPage(accountId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the filter above the history', () {
    testWidgets('it offers the orders and the expenses, and no in/out figures', (tester) async {
      // Act
      await openThePage(tester);

      // Assert
      expect(find.widgetWithText(FilterOptionChip, 'الكل'), findsOneWidget);
      expect(find.widgetWithText(FilterOptionChip, 'الطلبيات'), findsOneWidget);
      expect(find.widgetWithText(FilterOptionChip, 'المصاريف'), findsOneWidget);
      expect(find.textContaining('داخل'), findsNothing);
      expect(find.textContaining('خارج'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('the page opens on everything', (tester) async {
      // Act
      await openThePage(tester);

      // Assert
      final all = tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, 'الكل'));
      expect(all.isSelected, isTrue);
      verify(() => repository.movements(1, page: 1, filter: MovementFilter.all)).called(1);
      expect(find.text('إيجار', findRichText: true), findsOneWidget);
    });

    testWidgets('«المصاريف» asks for the expenses only and shows what came back', (tester) async {
      // Arrange
      await openThePage(tester);

      // Act
      await tester.tap(find.widgetWithText(FilterOptionChip, 'المصاريف'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.movements(1, page: 1, filter: MovementFilter.expenses)).called(1);
      final expenses = tester.widget<FilterOptionChip>(
        find.widgetWithText(FilterOptionChip, 'المصاريف'),
      );
      expect(expenses.isSelected, isTrue);
      expect(find.text('دفعة زبون'), findsNothing);
    });

    testWidgets('«الطلبيات» asks for the money orders own', (tester) async {
      // Arrange
      await openThePage(tester);

      // Act
      await tester.tap(find.widgetWithText(FilterOptionChip, 'الطلبيات'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.movements(1, page: 1, filter: MovementFilter.orders)).called(1);
    });
  });

  group('the search above the history', () {
    testWidgets('it asks for the order number typed, with a number keyboard', (tester) async {
      // Arrange
      await openThePage(tester);

      // Act
      await tester.enterText(find.byType(SearchField), '1290');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ابحث برقم الطلبية'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(of: find.byType(SearchField), matching: find.byType(TextField)),
      );
      expect(field.keyboardType, TextInputType.number);
      verify(
        () => repository.movements(1, page: 1, filter: MovementFilter.all, search: '1290'),
      ).called(1);
    });

    testWidgets('a filter picked after the search keeps the order number', (tester) async {
      // Arrange
      await openThePage(tester);
      await tester.enterText(find.byType(SearchField), '1290');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(FilterOptionChip, 'المصاريف'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.movements(1, page: 1, filter: MovementFilter.expenses, search: '1290'),
      ).called(1);
    });
  });

  group('what the history endpoint is sent', () {
    test('each filter is the query the server reads', () {
      // Assert
      expect(MovementFilter.all.query, isEmpty);
      expect(MovementFilter.orders.query, {'has_order': 1});
      expect(MovementFilter.expenses.query, {'kind': 'expense'});
    });
  });
}
