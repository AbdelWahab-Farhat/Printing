// أداةٌ لا اختبار: ترسم «محفظتي» صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا يجمعها
// `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/wallet_preview.dart
//
// على مقاس لوحة التصميم: ٣٩٠×٨٤٤ بكثافة ٢، بشريط حالةٍ ومؤشرٍ سفليّ كالآيفون. بالأرقام نفسها التي
// رُسم بها التصميم «ب · بطاقة FlyerX» — أمثلةٌ لا بيانات حقيقية.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/top_up_catalog.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/wallet_page.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockWallet extends Mock implements WalletRepository {}

class _MockTopUp extends Mock implements TopUpRepository {}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// الطرق التسع التي يعرضها التطبيق، بترتيب لوحة التصميم.
const _methodIds = [103, 104, 105, 102, 108, 106, 111, 107, 101];

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(MyWalletFilter.all));

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(() async {
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  final now = DateTime.now();
  DateTime at(int daysAgo, int hour, int minute) => DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

  final filled = [
    MyWalletEntry(id: 6, type: 'topup', typeLabel: 'شحن المحفظة', isIn: true, amount: '500.00', method: 'online', onlineMethod: 103, methodLabel: 'ون باي', occurredAt: at(0, 10, 42)),
    MyWalletEntry(id: 5, type: 'order_payment', typeLabel: 'دفع طلبية', isIn: false, amount: '860.00', orderId: 1304, orderCode: '1304', occurredAt: at(0, 9, 15)),
    MyWalletEntry(id: 4, type: 'order_refund', typeLabel: 'ردّ إلى المحفظة', isIn: true, amount: '120.00', orderId: 1288, orderCode: '1288', occurredAt: at(1, 16, 5)),
    MyWalletEntry(id: 3, type: 'topup', typeLabel: 'شحن المحفظة', isIn: true, amount: '1000.00', method: 'cash', methodLabel: 'كاش', occurredAt: at(1, 11, 20)),
    MyWalletEntry(id: 2, type: 'topup', typeLabel: 'شحن المحفظة', isIn: true, amount: '300.00', method: 'bank_transfer', methodLabel: 'حوالة', isReversed: true, occurredAt: at(4, 13, 10)),
    MyWalletEntry(id: 1, type: 'topup', typeLabel: 'شحن المحفظة', isIn: true, amount: '480.00', method: 'online', onlineMethod: 107, methodLabel: 'سداد', occurredAt: at(4, 18, 30)),
  ];

  Future<void> draw(
    WidgetTester tester, {
    required String name,
    required Brightness brightness,
    required List<MyWalletEntry> entries,
    required String balance,
  }) async {
    await sl.reset();

    final auth = _MockAuth();
    final wallet = _MockWallet();
    final topUp = _MockTopUp();

    when(auth.currentCustomer).thenAnswer(
      (_) async => const Right(CustomerAccount(id: 730, name: 'حساب تجريبي ٢', phone: '0910000002', code: 'A730')),
    );
    when(() => wallet.entries(page: any(named: 'page'), filter: any(named: 'filter'))).thenAnswer(
      (_) async => Right(
        Paginated(
          items: entries,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: entries.length),
          extraMeta: {'balance': balance},
        ),
      ),
    );
    when(topUp.methods).thenAnswer(
      (_) async => Right(
        TopUpMethods(
          enabled: true,
          feePayer: 'customer',
          methods: [
            for (final id in _methodIds) TopUpMethod(id: id, label: '$id', flow: 'otp', feePercentage: '2.5'),
          ],
        ),
      ),
    );

    sl
      ..registerLazySingleton(() => GetCurrentCustomer(auth))
      ..registerLazySingleton(() => GetTopUpMethods(topUp))
      ..registerFactory(() => WalletEntriesCubit(getEntries: GetWalletEntries(wallet)))
      ..registerLazySingleton(() => WalletBalanceCubit(getBalance: GetWalletBalance(wallet)));

    // آيفون بجزيرة: ٣٩٠×٨٤٤، شريط الحالة ٥٩، والمؤشر السفلي ٣٤.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: brightness == Brightness.light ? theme.light() : theme.dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const WalletPage(),
            );
          },
        ),
      ),
    );
    await tester.pump();

    // الشعارات تُقرأ من القرص فعلاً — خارج ساعة الاختبار المزيّفة، ثم إطارٌ يرسمها.
    final context = key.currentContext!;
    await tester.runAsync(() async {
      for (final id in _methodIds) {
        if (brandOf(id).asset case final asset?) await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw the wallet, ${brightness.name}', (tester) async {
      await draw(tester, name: 'wallet-${brightness.name}', brightness: brightness, entries: filled, balance: '1240.00');
    });
  }

  testWidgets('draw an empty wallet, light', (tester) async {
    await draw(tester, name: 'wallet-empty-light', brightness: Brightness.light, entries: const [], balance: '0.00');
  });
}
