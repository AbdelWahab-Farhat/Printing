import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/credit_categories_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/employee_wallet_page.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EmployeeWalletRepository {}

class _MockTreasury extends Mock implements TreasuryRepository {}

/// شاشة محفظة الموظف لمن يديرها: على شكل محفظة العميل، والأزرار داخل بطاقة الرصيد، ومن لا يملك
/// الصلاحية لا يراها أصلاً، ولا يحرّك أحدٌ محفظته بنفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  const withdrawal = EmployeeWalletEntry(
    id: 5,
    userId: 4,
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '1450.00',
    methodLabel: 'كاش',
    recorderName: 'سارة',
    canReverse: true,
  );

  const credit = EmployeeWalletEntry(
    id: 4,
    userId: 4,
    type: 'credit',
    typeLabel: 'مستحق',
    direction: 'in',
    amount: '2500.00',
    categoryName: 'رواتب',
    notes: 'راتب أكتوبر',
    recorderName: 'سارة',
  );

  const reversal = EmployeeWalletEntry(
    id: 6,
    userId: 4,
    type: 'reversal',
    typeLabel: 'عكس حركة',
    direction: 'in',
    amount: '1450.00',
    notes: 'كُتبت لموظفٍ آخر',
    recorderName: 'سارة',
  );

  const everything = [
    'users.wallet.view',
    'users.wallet.deposit',
    'users.wallet.credit',
    'users.wallet.withdraw',
    'users.wallet.adjust',
  ];

  Finder button(String label) => find.widgetWithText(AppButton, label);

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  setUpAll(() {
    registerFallbackValue(const EmployeeWalletLedger.mine());
    registerFallbackValue(EmployeeWalletEntryFilter.all);
    registerFallbackValue(
      const EmployeeMoneyDraft(amount: '1', method: EmployeeWalletMethod.cash),
    );
  });

  Future<void> open(
    WidgetTester tester, {
    List<String> permissions = everything,
    EmployeeWallet wallet = const EmployeeWallet(balance: '1050.00', canMove: true),
    List<EmployeeWalletEntry> entries = const [withdrawal, credit],
  }) async {
    await sl.reset();
    repository = _MockRepository();

    final treasury = _MockTreasury();
    when(
      () => treasury.expenseCategories(activeOnly: true),
    ).thenAnswer((_) async => const Right([]));

    when(() => repository.wallet(4)).thenAnswer((_) async => Right(wallet));
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
      ..registerSingleton<Session>(
        Session()
          ..adopt(AuthUser(id: 1, name: 'سارة', phone: '0911234567', permissions: permissions)),
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
      )
      ..registerFactory<CreditCategoriesCubit>(
        () => CreditCategoriesCubit(getCategories: GetExpenseCategories(treasury)),
      );

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
          home: EmployeeWalletPage(userId: 4, employeeName: 'محمد عز الدين'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// يترك توست النجاح أو الرفض ينتهي، فلا يبقى مؤقّتٌ بعد الاختبار.
  Future<void> letToastGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  tearDown(() => sl.reset());

  testWidgets('الرصيد في البطاقة الكبيرة، واسم الموظف تحت العنوان', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    final hero = tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile));
    expect(hero.amount, '1050.00');
    expect(hero.artwork, isNotNull);
    expect(find.text('المحفظة'), findsOneWidget);
    expect(find.text('محمد عز الدين'), findsOneWidget);
  });

  testWidgets('من يملك الصلاحيات يرى الأزرار الثلاثة داخل البطاقة', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    final hero = find.byType(InvestorMoneyTile);
    for (final label in ['إيداع', 'سحب', 'تعديل']) {
      expect(find.descendant(of: hero, matching: button(label)), findsOneWidget);
    }
  });

  testWidgets('من يملك السحب وحده يرى زرّه وحده', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['users.wallet.view', 'users.wallet.withdraw']);

    // Assert
    expect(button('سحب'), findsOneWidget);
    expect(button('إيداع'), findsNothing);
    expect(button('تعديل'), findsNothing);
  });

  testWidgets('«إيداع» يظهر لمن يملك المستحق وحده أيضاً', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['users.wallet.view', 'users.wallet.credit']);

    // Assert
    expect(button('إيداع'), findsOneWidget);
  });

  testWidgets('القارئ يرى الرقم وحده', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['users.wallet.view']);

    // Assert
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('لا أزرار على محفظة القارئ نفسه، ولو ملك كل الصلاحيات', (tester) async {
    // Arrange & Act
    await open(tester, wallet: const EmployeeWallet(balance: '1050.00'));

    // Assert
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('السطر يقول الطريقة أو التصنيف، و«إلغاء الحركة» حيث يقول الخادم', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(find.text('كاش'), findsOneWidget);
    expect(find.text('رواتب'), findsOneWidget);
    expect(find.text('راتب أكتوبر'), findsOneWidget);
    expect(find.text('−1,450 د.ل'), findsOneWidget);
    expect(find.text('+2,500 د.ل'), findsOneWidget);
    expect(find.text('إلغاء الحركة'), findsOneWidget);
  });

  testWidgets('رقائق الأنواع الخمس', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['users.wallet.view']);

    // Assert
    for (final filter in EmployeeWalletEntryFilter.values) {
      expect(find.text(filter.label), findsWidgets);
    }
  });

  testWidgets('محفظة لم تتحرّك تقول ذلك', (tester) async {
    // Arrange & Act
    await open(tester, entries: const []);

    // Assert
    expect(find.text('لم تتحرّك هذه المحفظة بعد'), findsOneWidget);
  });

  testWidgets('فشل القراءة يُقال، ويُعاد من الشاشة نفسها', (tester) async {
    // Arrange
    await open(tester);
    var calls = 0;
    when(() => repository.wallet(4)).thenAnswer(
      (_) async => calls++ == 0
          ? const Left(Failure.network(message: FailureMessages.noConnection))
          : const Right(EmployeeWallet(balance: '1050.00', canMove: true)),
    );
    await tester.pumpWidget(const SizedBox());
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
          home: EmployeeWalletPage(userId: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FailureMessages.noConnection), findsOneWidget);

    // Act
    await tester.tap(button('إعادة المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(InvestorMoneyTile), findsOneWidget);
    expect(find.text(FailureMessages.noConnection), findsNothing);
  });

  group('الكتابة', () {
    testWidgets('السحب يضيف سطره أعلى السجل، ويرسم رصيد الخادم', (tester) async {
      // Arrange
      await open(tester, entries: const [credit]);
      when(
        () => repository.withdraw(4, any(), clientToken: any(named: 'clientToken')),
      ).thenAnswer(
        (_) async => const Right(EmployeeWalletWrite(entry: withdrawal, balance: '550.00')),
      );
      await tester.tap(button('سحب'));
      await tester.pumpAndSettle();
      await tester.enterText(field('المبلغ'), '500');
      await tester.pump();

      // Act
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: button('سحب')));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).amount, '550.00');
      expect(find.text('−1,450 د.ل'), findsOneWidget);
      expect(find.text('تم السحب'), findsOneWidget);
      await letToastGo(tester);
    });

    testWidgets('الإعادة في الورقة نفسها ترسل الرمز نفسه، وفتحها من جديد رمزٌ جديد', (
      tester,
    ) async {
      // Arrange
      await open(tester);
      when(
        () => repository.withdraw(4, any(), clientToken: any(named: 'clientToken')),
      ).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );
      await tester.tap(button('سحب'));
      await tester.pumpAndSettle();
      await tester.enterText(field('المبلغ'), '500');
      await tester.pump();
      final submit = find.descendant(of: find.byType(BottomSheet), matching: button('سحب'));

      // Act
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      await letToastGo(tester);
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: button('إلغاء')));
      await tester.pumpAndSettle();
      await tester.tap(button('سحب'));
      await tester.pumpAndSettle();
      await tester.enterText(field('المبلغ'), '500');
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      await letToastGo(tester);

      // Assert
      final tokens = verify(
        () => repository.withdraw(4, any(), clientToken: captureAny(named: 'clientToken')),
      ).captured.cast<String>();

      expect(tokens, hasLength(3));
      expect(tokens[0], tokens[1]);
      expect(tokens[2], isNot(tokens[0]));
    });

    testWidgets('التعديل يكتب بورقة العميل نفسها ويرسم رصيد الخادم', (tester) async {
      // Arrange
      await open(tester);
      when(
        () => repository.adjust(
          4,
          amount: '150',
          credit: true,
          reason: 'رصيد افتتاحي',
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Right(EmployeeWalletWrite(entry: credit, balance: '1200.00')),
      );
      await tester.tap(button('تعديل'));
      await tester.pumpAndSettle();
      await tester.enterText(field('المبلغ'), '150');
      await tester.enterText(field('السبب'), 'رصيد افتتاحي');
      await tester.pump();

      // Act
      await tester.tap(button('إضافة للرصيد'));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).amount, '1200.00');
      expect(find.text('تم تعديل الرصيد'), findsOneWidget);
      await letToastGo(tester);
    });

    testWidgets('الإلغاء ورقةٌ بسبب، والأصل يُشطب وسطر العكس يُضاف', (tester) async {
      // Arrange
      await open(tester);
      when(() => repository.reverse(5, reason: 'كُتبت لموظفٍ آخر')).thenAnswer(
        (_) async => const Right(EmployeeWalletWrite(entry: reversal, balance: '2500.00')),
      );
      await tester.tap(find.text('إلغاء الحركة'));
      await tester.pumpAndSettle();
      expect(find.text('إلغاء «سحب»'), findsOneWidget);
      await tester.enterText(field('السبب'), 'كُتبت لموظفٍ آخر');
      await tester.pump();

      // Act
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: button('إلغاء الحركة')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).amount, '2500.00');
      expect(find.text('عكس حركة'), findsOneWidget);
      expect(find.text('أُلغيت — كُتبت لموظفٍ آخر'), findsOneWidget);
      expect(find.text('إلغاء الحركة'), findsNothing);
      expect(find.text('أُلغيت الحركة'), findsOneWidget);
      await letToastGo(tester);
    });

    testWidgets('رفض الإلغاء يُقال برسالة الخادم، ولا يتغيّر شيء', (tester) async {
      // Arrange
      await open(tester);
      const refused = 'لا يمكن عكس 1,450.00: سُحب جزءٌ من هذا المبلغ';
      when(() => repository.reverse(5, reason: 'خطأ كتابي')).thenAnswer(
        (_) async => const Left(Failure.server(message: refused)),
      );
      await tester.tap(find.text('إلغاء الحركة'));
      await tester.pumpAndSettle();
      await tester.enterText(field('السبب'), 'خطأ كتابي');
      await tester.pump();

      // Act
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: button('إلغاء الحركة')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(refused), findsOneWidget);
      expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).amount, '1050.00');
      expect(find.text('عكس حركة'), findsNothing);
      await letToastGo(tester);
    });
  });
}
