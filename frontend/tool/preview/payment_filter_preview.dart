// أداةٌ لا اختبار: ترسم ورقة «تصفية متقدمة» في «مراجعة وتسوية الدفعات» إلى PNG لتُرى بلا هاتف.
// خارج `test/` فلا يجمعها `flutter test`.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/payment_filter_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_queue_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = PaymentFilterOptions(
  kinds: [
    PaymentKind(label: 'حوالة', method: PaymentMethod.bankTransfer),
    PaymentKind(label: 'كاش نورس', accountId: 4),
    PaymentKind(label: 'مكتب قرجي', accountId: 1),
    PaymentKind(label: 'مكتب ولي العهد', accountId: 5),
    PaymentKind(label: 'ليبيانا', method: PaymentMethod.libyana),
    PaymentKind(label: 'بطاقة مصرفية', method: PaymentMethod.bankCard),
  ],
  accounts: [SettlementAccount(id: 6, name: 'حساب فرحات')],
  recorders: [PaymentPerson(id: 21, name: 'فرحات')],
  settlers: [PaymentPerson(id: 22, name: 'فرحات')],
);

Future<void> _draw(
  WidgetTester tester, {
  required String file,
  required PaymentAdvancedFilter current,
  bool offersType = false,
  bool offersSettled = false,
}) async {
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPaymentAdvancedFilter(
                  context: context,
                  current: current,
                  options: _options,
                  offersType: offersType,
                  offersSettled: offersSettled,
                ),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();

  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$file').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final loader = FontLoader('Cairo');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
      final file = File('../frontend-client/assets/fonts/Cairo-$weight.ttf');
      if (file.existsSync()) {
        loader.addFont(file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
      }
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

  testWidgets('the review sheet, empty', (tester) async {
    await _draw(tester, file: 'filter-review.png', current: const PaymentAdvancedFilter(), offersType: true);
  });

  testWidgets('the settled sheet, narrowed', (tester) async {
    await _draw(
      tester,
      file: 'filter-settled.png',
      current: PaymentAdvancedFilter(
        from: DateTime(2026, 10, 12),
        accountId: 1,
        detail: const PaymentDetailFilter(minAmount: '100', maxAmount: '500'),
      ),
      offersSettled: true,
    );
  });
}
