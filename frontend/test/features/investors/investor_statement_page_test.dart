import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investors/models/wallet_entry.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_statement_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_statement_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetStatement extends Mock implements GetInvestorStatement {}

class _MockReverse extends Mock implements ReverseWalletEntry {}

/// سجلُّ حركات المستثمر — ما يقوله الخادم عن كلّ سطر، وما يُسأل عنه حين يُفلتر أو يُلغى.
///
/// **الأسماءُ والإشاراتُ كما وصلت.** «اشتراك في الصندوق» يقوله الخادم، والإشارةُ من الرصيد الذي
/// حرّكه الصفّ — الشاشةُ لا تعيد تسمية شيءٍ ولا تخمّن اتجاهاً.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  late _MockGetStatement getStatement;
  late _MockReverse reverse;

  final subscription = WalletEntry.fromJson(const {
    'id': 12,
    'type': 'allocation',
    'type_label': 'اشتراك في الصندوق',
    'category': 'investment',
    'amount': '1000.00',
    'signed_amount': '-1000.00',
    'deal': {'id': 1, 'code': 'FUND', 'is_fund': true},
    'period': {'id': 3, 'code': 'P3'},
    'fund_units': {'units': '1000.000000', 'unit_price': '1.000000', 'locked_until': '2027-09-01'},
    'is_reversed': false,
    'can_be_reversed': true,
    'occurred_at': '2026-09-20T10:00:00+02:00',
    'recorded_by': {'id': 1, 'name': 'عبدالوهاب'},
  });

  final undoneDeposit = WalletEntry.fromJson(const {
    'id': 11,
    'type': 'deposit',
    'type_label': 'إيداع رأس مال',
    'category': 'capital',
    'amount': '500.00',
    'signed_amount': '500.00',
    'method': 'cash',
    'is_reversed': true,
    'can_be_reversed': false,
    'occurred_at': '2026-09-19T10:00:00+02:00',
  });

  Paginated<WalletEntry> page(List<WalletEntry> items) => Paginated<WalletEntry>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 25, lastPage: 1, total: items.length),
  );

  void register(List<String> permissions) {
    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
      )
      ..registerFactory<InvestorStatementCubit>(
        () => InvestorStatementCubit(getStatement: getStatement, reverseEntry: reverse),
      );
  }

  setUpAll(() {
    registerFallbackValue(WalletEntryCategory.capital);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    await sl.reset();
    getStatement = _MockGetStatement();
    reverse = _MockReverse();

    when(
      () => getStatement(
        any(),
        category: any(named: 'category'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => Right(page([subscription, undoneDeposit])));
  });

  tearDown(() async => sl.reset());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
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
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: InvestorStatementPage(investorId: 7, investorName: 'أحمد'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each row reads as the server named it, with its sign and its units', (
    tester,
  ) async {
    // Arrange
    register(const ['investors.view']);

    // Act
    await open(tester);

    // Assert
    expect(find.text('اشتراك في الصندوق'), findsOneWidget);
    expect(find.text('−1,000 د.ل'), findsOneWidget);
    expect(find.textContaining('الصندوق · فترة P3'), findsOneWidget);
    expect(find.text('1,000 وحدة × 1 د.ل'), findsOneWidget);
    expect(find.text('+500 د.ل'), findsOneWidget);
    expect(find.text('أُلغيت'), findsOneWidget);
  });

  testWidgets('a family is asked of the server, not filtered off the page', (tester) async {
    // Arrange
    register(const ['investors.view']);
    await open(tester);

    // Act
    await tester.tap(find.widgetWithText(FilterOptionChip, 'الأرباح'));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => getStatement(
        7,
        category: WalletEntryCategory.profit,
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: 1,
      ),
    ).called(1);
  });

  testWidgets('no reverse button for someone who cannot move his money', (tester) async {
    // Arrange
    register(const ['investors.view']);

    // Act
    await open(tester);

    // Assert
    expect(find.text('إلغاء الحركة'), findsNothing);
  });

  testWidgets('reversing asks first, sends the note, and reads the list again', (tester) async {
    // Arrange — the undone deposit offers nothing; only the subscription can be reversed.
    register(const ['investors.view', 'investors.money.record']);
    when(
      () => reverse(
        investorId: any(named: 'investorId'),
        entryId: any(named: 'entryId'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    await open(tester);
    expect(find.widgetWithText(TextButton, 'إلغاء الحركة'), findsOneWidget);

    // Act
    await tester.tap(find.widgetWithText(TextButton, 'إلغاء الحركة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'مبلغ خاطئ');
    await tester.tap(find.widgetWithText(TextButton, 'إلغاء الحركة').last);
    await tester.pumpAndSettle();

    // Assert
    verify(() => reverse(investorId: 7, entryId: 12, notes: 'مبلغ خاطئ')).called(1);
    verify(
      () => getStatement(
        7,
        category: any(named: 'category'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: 1,
      ),
    ).called(2);
    expect(find.text('أُلغيت الحركة'), findsOneWidget);

    // The snackbar dismisses itself on a timer; let it run out before the tree is torn down.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
