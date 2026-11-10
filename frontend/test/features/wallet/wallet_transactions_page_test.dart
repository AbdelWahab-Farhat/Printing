import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payments_cubit.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/views/wallet_transactions_page.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomers extends Mock implements WalletRepository {}

class _MockEmployees extends Mock implements EmployeeWalletRepository {}

class _MockOnline extends Mock implements OnlinePaymentRepository {}

/// «المعاملات المالية»: حركات العملاء والموظفين والمدفوعات الإلكترونية في شاشةٍ واحدة (طلب صاحب
/// العمل، ٢٠٢٦-١١-٠٧: «كلها معاملات مالية في النهاية»). كلُّ تبويبٍ بصلاحيته، ومن يملك واحدةً يرى
/// قائمتها وحدها، فلا طلبَ يعود بـ403.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCustomers customers;
  late _MockEmployees employees;
  late _MockOnline online;

  const customerGrant = 'customers.wallet.view';
  const employeeGrant = 'users.wallet.view';
  const onlineGrant = 'payments.online.view';
  const customerHint = 'ابحث باسم العميل أو هاتفه أو رمزه';
  const employeeHint = 'ابحث باسم الموظف أو هاتفه أو رمزه';
  const onlineHint = 'ابحث بالمرجع أو اسم الزبون أو هاتفه';
  const methodsTooltip = 'طرق الدفع وحدودها';

  const paid = CustomerWalletEntry(
    id: 8,
    customerId: 3,
    customerName: 'حساب تجريبي',
    type: 'order_payment',
    typeLabel: 'دفع طلبية',
    isIn: false,
    amount: '40.00',
  );

  const withdrawal = EmployeeWalletEntry(
    id: 5,
    userId: 4,
    user: EmployeeWalletPerson(id: 4, name: 'محمد عز الدين', code: 'E4'),
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '1450.00',
    methodLabel: 'كاش',
  );

  const intent = PaymentIntent(
    id: 4,
    uuid: 'b1c2',
    customerName: 'علي',
    methodLabel: 'سداد',
    status: IntentStatus.succeeded,
    statusLabel: 'تم الشحن',
    netAmount: '100.00',
    grossAmount: '102.50',
    customerFee: '2.50',
    feePayerLabel: 'الزبون',
    reference: 'DY-0004',
  );

  setUpAll(() {
    registerFallbackValue(IntentFilter.all);
    registerFallbackValue(WalletEntryFilter.all);
    registerFallbackValue(const EmployeeWalletLedger.all());
    registerFallbackValue(EmployeeWalletEntryFilter.all);
  });

  AuthUser account(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  Future<void> open(
    WidgetTester tester, {
    required List<String> permissions,
    String? opensOn,
  }) async {
    await sl.reset();
    customers = _MockCustomers();
    employees = _MockEmployees();
    online = _MockOnline();

    when(
      () => online.intents(
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated(
          items: [intent],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
          extraMeta: {'enabled': true, 'ezone_balance': '1250.00'},
        ),
      ),
    );
    when(
      () => customers.entries(
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated(
          items: [paid],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
        ),
      ),
    );
    when(
      () => employees.entries(
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
      ..registerSingleton<Session>(Session()..adopt(account(permissions)))
      ..registerFactoryParam<WalletEntriesCubit, int?, void>(
        (customerId, _) => WalletEntriesCubit(
          customerId: customerId,
          getEntries: GetCustomerWalletEntries(customers),
          reverseEntry: ReverseCustomerWalletEntry(customers),
        ),
      )
      ..registerFactoryParam<EmployeeWalletEntriesCubit, EmployeeWalletLedger, void>(
        (ledger, _) => EmployeeWalletEntriesCubit(
          ledger: ledger,
          getEntries: GetEmployeeWalletEntries(employees),
          reverseEntry: ReverseEmployeeWalletEntry(employees),
        ),
      )
      ..registerFactory<OnlinePaymentsCubit>(
        () => OnlinePaymentsCubit(
          getIntents: GetPaymentIntents(online),
          recheck: RecheckPaymentIntent(online),
        ),
      );

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
          home: WalletTransactionsPage(opensOn: opensOn),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => sl.reset());

  group('الفلتر', () {
    testWidgets('الرقائق تبدأ من حافة البحث، لا من وسط الشاشة', (tester) async {
      // Arrange
      const permissions = [customerGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      final search = tester.getRect(find.byType(SearchField));
      final first = tester.getRect(find.byType(FilterOptionChip).first);
      expect(first.right, moreOrLessEquals(search.right, epsilon: 0.5));
    });

    testWidgets('رقاقة النوع تقصر السجل عليه', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant]);

      // Act
      await tester.tap(find.text('الشحن'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => customers.entries(
          customerId: any(named: 'customerId'),
          page: 1,
          filter: WalletEntryFilter.topup,
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
      expect(
        tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, 'الشحن')).isSelected,
        isTrue,
      );
    });
  });

  group('من يرى ماذا', () {
    testWidgets('من يملك الصلاحيتين يرى تبويبين، والعملاء أولاً', (tester) async {
      // Arrange
      const permissions = [customerGrant, employeeGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      expect(find.text('المعاملات المالية'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'العملاء'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'الموظفون'), findsOneWidget);
      expect(find.text(customerHint), findsOneWidget);
      expect(find.text('حساب تجريبي'), findsOneWidget);
    });

    testWidgets('تبويب «الموظفون» يعرض حركات الموظفين', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant, employeeGrant]);

      // Act
      await tester.tap(find.widgetWithText(Tab, 'الموظفون'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(employeeHint), findsOneWidget);
      expect(find.text('محمد عز الدين · كاش'), findsOneWidget);
    });

    testWidgets('?tab=employees opens on the employees tab — the salary summary goes there', (
      tester,
    ) async {
      // Act
      await open(tester, permissions: const [customerGrant, employeeGrant], opensOn: 'employees');

      // Assert
      expect(find.text(employeeHint), findsOneWidget);
      expect(find.text('محمد عز الدين · كاش'), findsOneWidget);
    });

    testWidgets('a tab this reader does not have falls back to the first', (tester) async {
      // Act
      await open(tester, permissions: const [customerGrant, onlineGrant], opensOn: 'employees');

      // Assert
      expect(find.text(customerHint), findsOneWidget);
    });

    testWidgets('صلاحية العملاء وحدها: قائمتهم بلا تبويبات، ولا طلب للموظفين', (tester) async {
      // Arrange
      const permissions = [customerGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      expect(find.byType(TabBar), findsNothing);
      expect(find.text(customerHint), findsOneWidget);
      verifyNever(
        () => employees.entries(
          any(),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      );
    });

    testWidgets('صلاحية الموظفين وحدها: قائمتهم بلا تبويبات، ولا طلب للعملاء', (tester) async {
      // Arrange
      const permissions = [employeeGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      expect(find.text('المعاملات المالية'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.text(employeeHint), findsOneWidget);
      verifyNever(
        () => customers.entries(
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      );
    });

    testWidgets('من يملك الثلاث يرى ثلاثة تبويبات بهذا الترتيب', (tester) async {
      // Arrange
      const permissions = [customerGrant, employeeGrant, onlineGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      final labels = tester.widgetList<Tab>(find.byType(Tab)).map((tab) => tab.text);
      expect(labels, ['العملاء', 'الموظفون', 'الإلكترونية']);
    });

    testWidgets('تبويب «الإلكترونية» يعرض رصيد Ezone والمحاولات', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant, onlineGrant]);

      // Act
      await tester.tap(find.widgetWithText(Tab, 'الإلكترونية'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(onlineHint), findsOneWidget);
      expect(find.text('في Ezone'), findsOneWidget);
      expect(find.text('علي'), findsOneWidget);
    });

    testWidgets('صلاحية المدفوعات وحدها: قائمتها وزرّها، بلا تبويبات', (tester) async {
      // Arrange
      const permissions = [onlineGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      expect(find.byType(TabBar), findsNothing);
      expect(find.text(onlineHint), findsOneWidget);
      expect(find.byTooltip(methodsTooltip), findsOneWidget);
    });

    testWidgets('صلاحيةٌ تصل والشاشة مفتوحة تفتح تبويبها', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant]);

      // Act
      sl<Session>().adopt(account(const [customerGrant, employeeGrant]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TabBar), findsOneWidget);
    });
  });

  group('زر «طرق الدفع وحدودها»', () {
    testWidgets('لا يظهر على تبويب العملاء', (tester) async {
      // Arrange
      const permissions = [customerGrant, onlineGrant];

      // Act
      await open(tester, permissions: permissions);

      // Assert
      expect(find.byTooltip(methodsTooltip), findsNothing);
    });

    testWidgets('يظهر في شريط الشاشة مع تبويب «الإلكترونية»', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant, onlineGrant]);

      // Act
      await tester.tap(find.widgetWithText(Tab, 'الإلكترونية'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byTooltip(methodsTooltip)),
        findsOneWidget,
      );
    });

    testWidgets('يختفي عند الرجوع إلى تبويبٍ آخر', (tester) async {
      // Arrange
      await open(tester, permissions: const [customerGrant, onlineGrant]);
      await tester.tap(find.widgetWithText(Tab, 'الإلكترونية'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(Tab, 'العملاء'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byTooltip(methodsTooltip), findsNothing);
    });
  });

  testWidgets('الرجوع إلى التبويب يجد فلتره وسجلّه كما تركهما', (tester) async {
    // Arrange
    await open(tester, permissions: const [customerGrant, employeeGrant]);
    await tester.tap(find.text('الشحن'));
    await tester.pumpAndSettle();
    clearInteractions(customers);

    // Act
    await tester.tap(find.widgetWithText(Tab, 'الموظفون'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'العملاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, 'الشحن')).isSelected,
      isTrue,
    );
    verifyNever(
      () => customers.entries(
        customerId: any(named: 'customerId'),
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    );
  });
}
