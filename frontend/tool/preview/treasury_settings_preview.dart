// أداةٌ لا اختبار: ترسم «إعدادات المالية» وورقتين من أوراق ⓘ إلى PNG لتُرى بلا هاتف — بحسابات
// قاعدة البيانات المحلية وإعداداتها (2026-10-27). خارج `test/` فلا يجمعها `flutter test`.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/treasury_settings_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_settings_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

TreasuryAccount _account(
  int id,
  String name,
  AccountKind kind, {
  bool isDefault = false,
  bool isSystem = false,
  bool isSpendable = true,
}) => TreasuryAccount(
  id: id,
  name: name,
  kind: kind,
  kindLabel: '',
  isDefault: isDefault,
  isActive: true,
  isSystem: isSystem,
  isSpendable: isSpendable,
);

final _accounts = [
  _account(1, 'بريمولا قرجي', AccountKind.cash, isDefault: true),
  _account(5, 'بريمولا ولي العهد', AccountKind.cash),
  _account(2, 'المصرف', AccountKind.bank, isDefault: true),
  _account(6, 'حساب فرحات', AccountKind.bank),
  _account(3, 'ليبيانا', AccountKind.wallet, isDefault: true),
  _account(11, 'Ezone', AccountKind.wallet, isSystem: true),
  _account(4, 'النورس', AccountKind.custody, isSpendable: false),
];

const _settings = TreasurySettings(
  ownAccountFirst: true,
  blockOverdraft: true,
  withdrawalNeedsReason: true,
  askCarrierFee: false,
  collections: {AccountKind.cash: CollectionSetting(on: true)},
  settleIntoSettler: true,
  pickupOffices: [
    PickupOffice(cityId: 1, name: 'إستلام مكتب(قرجي)', accountId: 1, accountName: 'بريمولا قرجي'),
    PickupOffice(
      cityId: 2,
      name: 'إستلام مكتب(ولي العهد)',
      accountId: 5,
      accountName: 'بريمولا ولي العهد',
    ),
  ],
  onlineFeePayer: 'customer',
);

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Cairo بأوزانه من تطبيق العميل إن وُجد بجانبه — أقربُ إلى الهاتف — وإلا Almarai كبقية الأدوات.
    final cairo = Directory('../frontend-client/assets/fonts');
    final files = cairo.existsSync()
        ? ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'].map((w) => '${cairo.path}/Cairo-$w.ttf')
        : ['assets/fonts/Almarai-Regular.ttf', 'assets/fonts/Almarai-Bold.ttf'];
    final loader = FontLoader('Cairo');
    for (final file in files) {
      loader.addFont(File(file).readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
    }
    await loader.load();

    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.view(bytes.buffer)),
        );
      await icons.load();
    }
  });

  Future<void> draw(
    WidgetTester tester,
    String name, {
    String? tooltip,
    double scroll = 0,
  }) async {
    await Injector.reset();
    final repository = _MockTreasuryRepository();
    when(repository.settings).thenAnswer((_) async => const Right(_settings));
    when(repository.accounts).thenAnswer(
      (_) async => Right(TreasuryAccounts(accounts: _accounts, total: '0.00', canViewAll: true)),
    );
    sl
      ..registerLazySingleton(() => GetTreasurySettings(repository))
      ..registerLazySingleton(() => SaveTreasurySettings(repository))
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => SetSettlesInto(repository));

    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MaterialTheme(Typography.material2021().white.apply(fontFamily: 'Cairo')).dark(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const TreasurySettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (scroll > 0) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll));
      await tester.pumpAndSettle();
    }

    if (tooltip != null) {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();
    }

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('draw the top', (tester) => draw(tester, 'settings-1'));

  testWidgets('draw the middle', (tester) => draw(tester, 'settings-2', scroll: 640));

  testWidgets('draw the bottom', (tester) => draw(tester, 'settings-3', scroll: 2000));

  testWidgets('draw «الدفعة» ⓘ', (tester) => draw(tester, 'explain-payment', tooltip: 'شرح: الدفعة'));

  testWidgets(
    'draw «حساب المسوّي» ⓘ',
    (tester) => draw(
      tester,
      'explain-settler',
      tooltip: 'ما معنى: إلى حساب المسوّي تلقائياً',
      scroll: 640,
    ),
  );
}
