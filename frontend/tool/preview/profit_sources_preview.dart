// أداةٌ لا اختبار: ترسم صفحة «أرباح معلّقة» إلى PNG لتُرى بلا هاتف — بأرقام لقطة الهاتف
// (2026-10-23). خارج `test/` فلا يجمعها `flutter test`.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/profit_sources_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/profit_sources_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/profit_sources_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetProfitSources extends Mock implements GetProfitSources {}

Map<String, Object?> _order(int code, String customer, String status, String state, String amount) => {
  'kind': 'order',
  'key': 'order:$code:$state',
  'order_id': code,
  'code': '$code',
  'customer_name': customer,
  'order_status_label': status,
  'state': state,
  'state_label': switch (state) {
    'awaiting_period_end' => 'بانتظار انتهاء الفترة',
    _ => 'بانتظار إقفال الصفقة',
  },
  'amount': amount,
};

final _pending = ProfitSources.fromJson({
  'gate': 'pending',
  'total': '2027.39',
  'groups': [
    {
      'key': 'period:2',
      'title': 'P2',
      'starts_on': '2026-10-01',
      'ends_on': '2026-10-31',
      'status': 'open',
      'status_label': 'مفتوحة',
      'total': '1050.41',
      'lines': [
        _order(1308, 'عميل تجريبي', 'جاهزة للطباعة', 'awaiting_period_end', '50.02'),
        _order(1307, 'عميل تجريبي', 'جاهزة', 'awaiting_period_end', '1000.39'),
      ],
    },
    {
      // الصفقةُ القديمة كما جاءت على الهاتف: اسمُها فارغ.
      'key': 'deal:1',
      'title': '',
      'total': '976.98',
      'lines': [
        _order(1295, 'ميو', 'تم الاستلام', 'awaiting_deal_close', '10.00'),
        _order(1287, 'Bloom', 'تم التسوية', 'awaiting_deal_close', '11.41'),
        _order(1290, 'قيصر', 'تم التسوية', 'awaiting_deal_close', '50.02'),
        _order(1283, 'رصف', 'جاهزة', 'awaiting_deal_close', '5.50'),
        _order(1282, 'sara Aletery', 'جاهزة', 'awaiting_deal_close', '9.50'),
        _order(1280, 'كارز', 'جاهزة', 'awaiting_deal_close', '17.00'),
        _order(1260, 'meme queen', 'تم الاستلام', 'awaiting_deal_close', '13.00'),
        _order(1297, 'سراج', 'جاهزة للطباعة', 'awaiting_deal_close', '6.50'),
        _order(1273, 'اسامة حماد', 'جاري التوصيل', 'awaiting_deal_close', '15.00'),
      ],
    },
  ],
});

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

  testWidgets('draw profit-sources', (tester) async {
    await Injector.reset();
    final getSources = _MockGetProfitSources();
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(_pending));
    sl.registerFactory<ProfitSourcesCubit>(() => ProfitSourcesCubit(getSources: getSources));

    tester.view.physicalSize = const Size(430, 1500);
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
            home: const ProfitSourcesPage(investorId: 7, gate: ProfitGate.pending),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/profit-sources.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
