// A harness, not a test: it draws the customer screen, the wallet screen and its two sheets to
// PNGs so a change can be looked at without the phone. Named outside `test/` so `flutter test`
// never collects it.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/customer_wallet_preview.dart
//
// The app's text is the system face on the phone; Cairo stands in for it here, a little wider,
// so a label that fits in this picture fits on the phone.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart' show Right;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customer_detail_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/views/customer_wallet_page.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomers extends Mock implements CustomerRepository {}

class _MockOrders extends Mock implements OrderRepository {}

class _MockWallets extends Mock implements WalletRepository {}

class _MockTreasury extends Mock implements TreasuryRepository {}

const _customer = Customer(
  id: 7,
  code: 'A730',
  name: 'حساب تجريبي ٢',
  phone: '0910000002',
  isActive: true,
  shops: [],
);

final _now = DateTime.now();

final _entries = [
  CustomerWalletEntry(
    id: 2,
    customerId: 7,
    type: 'topup',
    typeLabel: 'شحن المحفظة',
    isIn: true,
    amount: '20000.00',
    methodLabel: 'دفع إلكتروني',
    occurredAt: _now.subtract(const Duration(minutes: 5)),
  ),
  CustomerWalletEntry(
    id: 1,
    customerId: 7,
    type: 'topup',
    typeLabel: 'شحن المحفظة',
    isIn: true,
    amount: '200.00',
    methodLabel: 'دفع إلكتروني',
    occurredAt: _now.subtract(const Duration(days: 1)),
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
    registerFallbackValue(WalletEntryFilter.all);
    await _loadFonts();
  });

  testWidgets('draw the customer and the wallet', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    debugDisableShadows = false;

    try {
      final customers = _MockCustomers();
      final orders = _MockOrders();
      final wallets = _MockWallets();
      final treasury = _MockTreasury();

      when(() => customers.customer(7)).thenAnswer((_) async => const Right(_customer));
      when(
        () => orders.statusCounts(
          search: any(named: 'search'),
          customerId: any(named: 'customerId'),
        ),
      ).thenAnswer(
        (_) async => const Right(OrderCounts(byStatus: {'new': 2}, total: 2)),
      );
      when(() => wallets.wallet(7)).thenAnswer(
        (_) async => const Right(CustomerWallet(customerId: 7, balance: '20200.00')),
      );
      when(
        () => wallets.entries(
          customerId: 7,
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right(
          Paginated(
            items: _entries,
            meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
          ),
        ),
      );
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

      // لا `Injector.reset()`: الأداة تعمل في عزلٍ جديد لم يُسجَّل فيه شيء بعد.
      sl
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              AuthUser(
                id: 4,
                name: 'فرحات',
                phone: '0911234567',
                permissions: [for (final permission in AppPermission.values) permission.wire],
              ),
            ),
        )
        ..registerFactoryParam<CustomerDetailCubit, int, void>(
          (customerId, _) => CustomerDetailCubit(
            customerId: customerId,
            getCustomer: GetCustomer(customers),
            setActivation: SetCustomerActivation(customers),
          ),
        )
        ..registerFactoryParam<CustomerOrderCountsCubit, int, void>(
          (customerId, _) => CustomerOrderCountsCubit(
            customerId: customerId,
            getCounts: GetOrderCounts(orders),
          ),
        )
        ..registerFactoryParam<CustomerWalletCubit, int, void>(
          (customerId, _) => CustomerWalletCubit(
            customerId: customerId,
            getWallet: GetCustomerWallet(wallets),
            topUp: TopUpCustomerWallet(wallets),
            adjust: AdjustCustomerWallet(wallets),
          ),
        )
        ..registerFactoryParam<WalletEntriesCubit, int?, void>(
          (customerId, _) => WalletEntriesCubit(
            customerId: customerId,
            getEntries: GetCustomerWalletEntries(wallets),
            reverseEntry: ReverseCustomerWalletEntry(wallets),
          ),
        )
        ..registerSingleton(GetAccountOptions(treasury))
        ..registerSingleton(GetTreasuryAccounts(treasury));

      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      final theme = MaterialTheme(Typography.material2021().black.apply(fontFamily: 'Cairo'));

      Future<GlobalKey> draw(Widget page, {bool dark = true}) async {
        tester.view.physicalSize = const Size(440 * 3, 956 * 3);

        // شجرةٌ جديدة لكل صورة: بلا هذا يُبقي الإطارُ Navigator السابق ولا يُفتح شيء.
        await tester.pumpWidget(const SizedBox());

        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ScreenUtilInit(
              designSize: const Size(430, 932),
              builder: (context, _) => MaterialApp(
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
                home: _Launcher(page: page),
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

      const customerPage = CustomerDetailPage(customerId: 7);
      const walletPage = CustomerWalletPage(customerId: 7, customerName: 'حساب تجريبي ٢');

      await shoot(await draw(customerPage), 'wallet-1-customer');
      await shoot(await draw(walletPage), 'wallet-2-wallet');

      final topUp = await draw(walletPage);
      await tester.tap(find.widgetWithText(AppButton, 'شحن المحفظة'));
      await tester.pumpAndSettle();
      await shoot(topUp, 'wallet-3-top-up');

      final adjust = await draw(walletPage);
      await tester.tap(find.widgetWithText(AppButton, 'تعديل الرصيد'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '150');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shoot(adjust, 'wallet-4-adjust');

      await shoot(await draw(customerPage, dark: false), 'wallet-5-customer-light');
      await shoot(await draw(walletPage, dark: false), 'wallet-6-wallet-light');
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugDisableShadows = true;
    }
  });
}
