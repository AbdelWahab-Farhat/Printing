// أداةٌ لا اختبار: ترسم محفظة الموظف وأوراقها ومداخلها إلى PNG لتُرى بلا هاتف، لتُقارَن بلوحة
// Claude Design. خارج `test/` فلا يجمعها `flutter test`. الأسماء والأرقام توضيحية.
//
//   FLUTTER_ROOT=… PREVIEW_OUT=/tmp/out flutter test tool/preview/employee_wallet_preview.dart
//
// خطُّ التطبيق هو Cairo نفسه، لكنه يُحمَّل هنا من ملفاته لأن الاختبار لا يصل إلى الشبكة.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' show Either, Right;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:dayaa/features/access/presentation/views/employee_detail_page.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/get_user.dart';
import 'package:dayaa/features/access/usecases/set_employee_service_price.dart';
import 'package:dayaa/features/access/usecases/set_user_activation.dart';
import 'package:dayaa/features/access/usecases/set_user_password.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';
import 'package:dayaa/features/auth/usecases/get_current_user.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_tickets_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/credit_categories_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/employee_wallet_page.dart';
import 'package:dayaa/features/employee_wallet/presentation/views/my_wallet_page.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:dayaa/features/home/presentation/views/home_page.dart';
import 'package:dayaa/features/home/repositories/home_repository.dart';
import 'package:dayaa/features/home/usecases/get_home_summary.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/usecases/get_unread_count.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payments_cubit.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/views/wallet_transactions_page.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWallets extends Mock implements EmployeeWalletRepository {}

class _MockTreasury extends Mock implements TreasuryRepository {}

class _MockCustomerWallets extends Mock implements WalletRepository {}

class _MockOnlinePayments extends Mock implements OnlinePaymentRepository {}

class _MockAccess extends Mock implements AccessRepository {}

class _MockAuth extends Mock implements AuthRepository {}

class _MockHome extends Mock implements HomeRepository {}

class _MockGetUnreadCount extends Mock implements GetUnreadCount {}

class _MockTickets extends MockCubit<InternalTicketsHomeState>
    implements InternalTicketsHomeCubit {}

class _Tickets implements DesignTicketRepository {
  static DesignTicket _ticket(int id, String title, String label, DesignTicketStatus status) =>
      DesignTicket(
        id: id,
        code: 'D$id',
        title: title,
        description: '',
        status: status,
        statusLabel: label,
        customerId: 4,
        customerName: 'A713',
        customerCode: 'A713',
        isInSharedPool: status == DesignTicketStatus.fresh,
      );

  @override
  Future<Either<Failure, Paginated<DesignTicket>>> tickets({
    List<String> statuses = const <String>[],
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async => Right(
    Paginated<DesignTicket>(
      items: [
        _ticket(128, 'شعار مقهى الواحة', 'قيد التصميم', DesignTicketStatus.inProgress),
        _ticket(131, 'تصميم كيس عيد الأضحى', 'جديد', DesignTicketStatus.fresh),
        _ticket(119, 'كرت عمل', 'قيد التصميم', DesignTicketStatus.inProgress),
      ],
      meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 3),
    ),
  );

  @override
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) async => const Right(DesignTicketCounts(byStatus: {'new': 1, 'in_progress': 2}, total: 3));

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _now = DateTime.now();

final _entries = [
  EmployeeWalletEntry(
    id: 7,
    userId: 4,
    type: 'reversal',
    typeLabel: 'عكس حركة',
    direction: 'in',
    amount: '350.00',
    notes: 'كُتبت لموظفٍ آخر',
    recorderName: 'سارة',
    occurredAt: _now,
  ),
  EmployeeWalletEntry(
    id: 6,
    userId: 4,
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '350.00',
    methodLabel: 'ليبيانا',
    recorderName: 'سارة',
    isReversed: true,
    reversalReason: 'كُتبت لموظفٍ آخر',
    occurredAt: _now.subtract(const Duration(minutes: 7)),
  ),
  EmployeeWalletEntry(
    id: 5,
    userId: 4,
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '1450.00',
    methodLabel: 'كاش',
    recorderName: 'سارة',
    canReverse: true,
    occurredAt: _now.subtract(const Duration(minutes: 20)),
  ),
  EmployeeWalletEntry(
    id: 4,
    userId: 4,
    type: 'credit',
    typeLabel: 'مستحق',
    direction: 'in',
    amount: '2500.00',
    categoryName: 'رواتب',
    notes: 'راتب أكتوبر',
    recorderName: 'سارة',
    canReverse: true,
    occurredAt: _now.subtract(const Duration(days: 5)),
  ),
  EmployeeWalletEntry(
    id: 3,
    userId: 4,
    type: 'deposit',
    typeLabel: 'إيداع',
    direction: 'in',
    amount: '300.00',
    methodLabel: 'حوالة',
    recorderName: 'سارة',
    occurredAt: _now.subtract(const Duration(days: 9)),
  ),
];

/// يفتح الصفحة فوق شاشةٍ أخرى، فيظهر زرّ الرجوع كما على الهاتف.
class _Launcher extends StatefulWidget {
  const _Launcher({required this.page});

  final Widget page;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => widget.page)),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

Future<ByteData> _bytes(String path) =>
    File(path).readAsBytes().then((bytes) => ByteData.view(bytes.buffer));

Future<void> _loadFonts() async {
  final cairo = FontLoader('Cairo');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    cairo.addFont(_bytes('../frontend-client/assets/fonts/Cairo-$weight.ttf'));
  }
  await cairo.load();

  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final cupertinoRoot = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((package) => package['name'] == 'cupertino_icons')['rootUri'] as String;
  await (FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(_bytes('${Uri.parse(cupertinoRoot).toFilePath()}/assets/CupertinoIcons.ttf')))
      .load();

  if (Platform.environment['FLUTTER_ROOT'] case final flutterRoot?) {
    await (FontLoader('MaterialIcons')
          ..addFont(_bytes('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')))
        .load();
  }
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(() async {
    registerFallbackValue(const EmployeeWalletLedger.mine());
    registerFallbackValue(EmployeeWalletEntryFilter.all);
    registerFallbackValue(WalletEntryFilter.all);
    registerFallbackValue(IntentFilter.all);
    await _loadFonts();
  });

  testWidgets('draw the wallet and its doors', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    debugDisableShadows = false;

    try {
      final wallets = _MockWallets();
      final treasury = _MockTreasury();
      final access = _MockAccess();
      final auth = _MockAuth();
      final home = _MockHome();
      final unread = _MockGetUnreadCount();
      final tickets = _MockTickets();

      const person = AuthUser(
        id: 4,
        name: 'محمد عز الدين',
        phone: '0944909851',
        email: 'mohamed@example.com',
        employeeCode: 'E4',
        salary: '2500.00',
        roles: [UserRole(name: 'designer', label: 'مصمم')],
      );

      when(() => wallets.wallet(4)).thenAnswer(
        (_) async =>
            const Right(EmployeeWallet(balance: '1500.00', canMove: true, salary: '2500.00')),
      );
      when(wallets.myWallet).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '1500.00')),
      );
      when(
        () => wallets.entries(
          any(),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((invocation) async {
        final ledger = invocation.positionalArguments.first as EmployeeWalletLedger;
        final rows = [
          for (final entry in _entries)
            switch (ledger) {
              EmployeeWalletLedgerMine() => entry.copyWith(
                recorderName: null,
                canReverse: false,
                userId: null,
              ),
              EmployeeWalletLedgerAll() => entry.copyWith(
                user: const EmployeeWalletPerson(id: 4, name: 'محمد عز الدين', code: 'E4'),
                canReverse: false,
              ),
              EmployeeWalletLedgerOf() => entry,
            },
        ];

        return Right(
          Paginated(
            items: rows,
            meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: rows.length),
          ),
        );
      });

      when(
        () => treasury.accountOptions(
          method: any(named: 'method'),
          incoming: any(named: 'incoming'),
          orderId: any(named: 'orderId'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          AccountOptions(accounts: [], suggestedId: 1, suggestedName: 'بريمولا قرجي'),
        ),
      );
      when(() => treasury.expenseCategories(activeOnly: true)).thenAnswer(
        (_) async => const Right([
          ExpenseCategory(
            id: 1,
            name: 'رواتب',
            code: 'salary',
            requiresEmployee: false,
            isActive: true,
            isSystem: true,
          ),
          ExpenseCategory(
            id: 2,
            name: 'مكافآت',
            requiresEmployee: false,
            isActive: true,
            isSystem: false,
          ),
        ]),
      );

      when(() => access.user(4)).thenAnswer((_) async => const Right(person));
      when(auth.currentUser).thenAnswer(
        (_) async => const Right(
          AuthUser(
            id: 7,
            name: 'سارة علي',
            phone: '0911234567',
            employeeCode: 'E7',
            permissions: [],
            roles: [UserRole(name: 'staff', label: 'موظف')],
          ),
        ),
      );
      when(home.summary).thenAnswer(
        (_) async => const Right(
          HomeSummary(totalOrders: 9651, customersCount: 1284, dailyOrders: 36, monthlyOrders: 412),
        ),
      );
      when(unread.call).thenAnswer((_) async => const Right(UnreadCount(count: 0)));
      whenListen(
        tickets,
        const Stream<InternalTicketsHomeState>.empty(),
        initialState: const InternalTicketsHomeState.loaded(home: InternalTicketsHome()),
      );
      when(tickets.load).thenAnswer((_) async {});
      when(tickets.close).thenAnswer((_) async {});

      final customerWallets = _MockCustomerWallets();
      final onlinePayments = _MockOnlinePayments();

      when(
        () => customerWallets.entries(
          customerId: any(named: 'customerId'),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right(
          Paginated(
            items: [
              CustomerWalletEntry(
                id: 8,
                customerId: 3,
                customerName: 'حساب تجريبي',
                type: 'order_payment',
                typeLabel: 'دفع طلبية',
                isIn: false,
                amount: '231.00',
                notes: 'الطلبية 1319',
                occurredAt: DateTime(2026, 10, 20, 14, 57),
              ),
            ],
            meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
          ),
        ),
      );
      when(
        () => onlinePayments.intents(
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          Paginated(
            items: [
              PaymentIntent(
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
              ),
            ],
            meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
            extraMeta: {'enabled': true, 'ezone_balance': '21670.02'},
          ),
        ),
      );

      final session = Session();

      void signIn(List<String> permissions) => session.adopt(
        AuthUser(id: 1, name: 'سارة', phone: '0911234567', permissions: permissions),
      );

      // لا `Injector.reset()`: الأداة تعمل في عزلٍ جديد لم يُسجَّل فيه شيء بعد.
      sl
        ..registerSingleton<Session>(session)
        ..registerFactoryParam<WalletEntriesCubit, int?, void>(
          (customerId, _) => WalletEntriesCubit(
            customerId: customerId,
            getEntries: GetCustomerWalletEntries(customerWallets),
            reverseEntry: ReverseCustomerWalletEntry(customerWallets),
          ),
        )
        ..registerFactory<OnlinePaymentsCubit>(
          () => OnlinePaymentsCubit(
            getIntents: GetPaymentIntents(onlinePayments),
            recheck: RecheckPaymentIntent(onlinePayments),
          ),
        )
        ..registerFactoryParam<EmployeeWalletCubit, int, void>(
          (userId, _) => EmployeeWalletCubit(
            userId: userId,
            getWallet: GetEmployeeWallet(wallets),
            deposit: DepositToEmployeeWallet(wallets),
            credit: CreditEmployeeWallet(wallets),
            withdraw: WithdrawFromEmployeeWallet(wallets),
            adjust: AdjustEmployeeWallet(wallets),
          ),
        )
        ..registerFactoryParam<EmployeeWalletEntriesCubit, EmployeeWalletLedger, void>(
          (ledger, _) => EmployeeWalletEntriesCubit(
            ledger: ledger,
            getEntries: GetEmployeeWalletEntries(wallets),
            reverseEntry: ReverseEmployeeWalletEntry(wallets),
          ),
        )
        ..registerFactory<MyWalletCubit>(() => MyWalletCubit(getWallet: GetMyWallet(wallets)))
        ..registerFactory<CreditCategoriesCubit>(
          () => CreditCategoriesCubit(getCategories: GetExpenseCategories(treasury)),
        )
        ..registerFactoryParam<EmployeeDetailCubit, int, void>(
          (userId, _) => EmployeeDetailCubit(
            userId: userId,
            getUser: GetUser(access),
            setPassword: SetUserPassword(access),
            setServicePrice: SetEmployeeServicePrice(access),
            setActivation: SetUserActivation(access),
          ),
        )
        ..registerFactory<HomeCubit>(
          () => HomeCubit(
            getCurrentUser: GetCurrentUser(auth),
            getHomeSummary: GetHomeSummary(home),
          ),
        )
        ..registerFactory<InternalTicketsHomeCubit>(() => tickets)
        ..registerFactory<DesignTicketsCubit>(() {
          final repository = _Tickets();

          return DesignTicketsCubit(
            getTickets: GetDesignTickets(repository),
            getCounts: GetDesignTicketCounts(repository),
            acceptTicket: AcceptDesignTicket(repository),
          );
        })
        ..registerSingleton(GetAccountOptions(treasury))
        ..registerSingleton(GetTreasuryAccounts(treasury));

      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      final theme = MaterialTheme(Typography.material2021().black.apply(fontFamily: 'Cairo'));

      Future<GlobalKey> draw(Widget page, {bool dark = true, bool pushed = true}) async {
        tester.view.physicalSize = const Size(440 * 3, 956 * 3);

        // شجرةٌ جديدة لكل صورة: بلا هذا يُبقي الإطارُ Navigator السابق ولا يُفتح شيء.
        await tester.pumpWidget(const SizedBox());

        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ScreenUtilInit(
              designSize: const Size(430, 932),
              builder: (context, _) => BlocProvider(
                create: (_) => UnreadBadgeCubit(unread),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme.light(),
                  darkTheme: theme.dark(),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  locale: const Locale('ar'),
                  supportedLocales: const [Locale('ar')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: pushed ? _Launcher(page: page) : page,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        return key;
      }

      Future<void> shoot(GlobalKey key, String name) async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      const manager = [
        'users.view',
        'users.salary',
        'users.wallet.view',
        'users.wallet.deposit',
        'users.wallet.credit',
        'users.wallet.withdraw',
        'users.wallet.adjust',
      ];
      const walletPage = EmployeeWalletPage(userId: 4, employeeName: 'محمد عز الدين');

      Future<void> quiet() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      signIn([AppPermission.viewOrders.wire, AppPermission.manageOrders.wire]);
      await shoot(
        await draw(const Scaffold(body: HomePage()), pushed: false),
        'ew-01-home',
      );

      signIn([
        AppPermission.viewDesignTickets.wire,
        AppPermission.acceptDesignTickets.wire,
        AppPermission.submitDesignTickets.wire,
      ]);
      await shoot(await draw(const DesignTicketsPage(), pushed: false), 'ew-02-designer');

      signIn(manager);
      await shoot(await draw(const EmployeeDetailPage(userId: 4)), 'ew-03-employee');
      await shoot(await draw(walletPage), 'ew-04-wallet');

      final deposit = await draw(walletPage);
      await tester.tap(find.widgetWithText(AppButton, 'إيداع'));
      await tester.pumpAndSettle();
      await quiet();
      await shoot(deposit, 'ew-05-deposit-money');

      await tester.tap(find.text('مال مستحق'));
      await tester.pumpAndSettle();
      await shoot(deposit, 'ew-06-deposit-credit');

      await tester.tap(find.byTooltip('الفرق بين مال مستلم ومال مستحق'));
      await tester.pumpAndSettle();
      await quiet();
      await shoot(deposit, 'ew-14-deposit-explain');

      final withdraw = await draw(walletPage);
      await tester.tap(find.widgetWithText(AppButton, 'سحب'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '500');
      await tester.pumpAndSettle();
      await quiet();
      await shoot(withdraw, 'ew-07-withdraw');

      final adjust = await draw(walletPage);
      await tester.tap(find.widgetWithText(AppButton, 'تعديل'));
      await tester.pumpAndSettle();
      await quiet();
      await shoot(adjust, 'ew-08-adjust');

      final reverse = await draw(walletPage);
      await tester.tap(find.text('إلغاء الحركة').first);
      await tester.pumpAndSettle();
      await quiet();
      await shoot(reverse, 'ew-09-reverse');

      await shoot(await draw(const MyWalletPage()), 'ew-10-my-wallet');
      await shoot(await draw(const WalletTransactionsPage()), 'ew-11-movements');

      signIn([
        ...manager,
        AppPermission.viewCustomerWallets.wire,
        AppPermission.viewOnlinePayments.wire,
      ]);
      final transactions = await draw(const WalletTransactionsPage());
      await shoot(transactions, 'ew-15-transactions-customers');
      await tester.tap(find.widgetWithText(Tab, 'الموظفون'));
      await tester.pumpAndSettle();
      await shoot(transactions, 'ew-16-transactions-employees');
      await tester.tap(find.widgetWithText(Tab, 'الإلكترونية'));
      await tester.pumpAndSettle();
      await shoot(transactions, 'ew-17-transactions-online');
      signIn(manager);

      await shoot(await draw(walletPage, dark: false), 'ew-12-wallet-light');

      signIn([AppPermission.viewOrders.wire]);
      await shoot(
        await draw(const Scaffold(body: HomePage()), pushed: false, dark: false),
        'ew-13-home-light',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugDisableShadows = true;
    }
  });
}
