// أداةٌ لا اختبار: ترسم «دفعات الطلبية» صوراً ليُرى التصميم «ب» بلا هاتف. خارج `test/` فلا
// يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد> \
//   PREVIEW_ICONS=<flutter>/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf \
//     flutter test tool/preview/order_payments_preview.dart
//
// **بمقاس آيفون المالك** — 440×956 بكثافة 3، كلقطته تماماً — وبأيقونات iOS، وبخطّ Cairo
// الحقيقي من حزمة تطبيق العميل: Almarai الذي تستعيره الأدوات الأخرى يغيّر عرض كل سطر. والظلّ
// يُرسم حقيقياً (`debugDisableShadows`)، وإلا خرج ظلّ «تسجيل دفعة» شريطاً صلباً.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_payments_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentsCubit extends MockCubit<OrderPaymentsState> implements OrderPaymentsCubit {}

const _office = PaymentAccountRef(id: 3, name: 'بريمولا قرجي', kind: 'cash');
const _nawris = PaymentAccountRef(id: 9, name: 'النورس', kind: 'custody');
const _bank = PaymentAccountRef(id: 2, name: 'المصرف', kind: 'bank');
const _farhat = PaymentRecorder(id: 4, name: 'فرحات');
const _sara = PaymentRecorder(id: 5, name: 'سارة');
const _mona = PaymentRecorder(id: 6, name: 'منى');

/// الطلبية 1307 كما في لقطة المالك: دفعةٌ كاش لم تُراجَع، ومالها في «بريمولا قرجي».
final _order1307 = OrderLedger(
  payments: [
    OrderPayment(
      id: 1,
      orderId: 1307,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: '226.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      recordedBy: _farhat,
      paidAt: DateTime(2026, 10, 8, 12, 50),
      isReversible: true,
      requiresReview: true,
      canReview: true,
      treasuryAccount: _office,
      canSettle: true,
    ),
  ],
  summary: const PaymentSummary(
    grandTotal: '226.00',
    paidAmount: '226.00',
    remainingAmount: '0.00',
    paymentStatus: PaymentStatus.paid,
    paymentStatusLabel: 'مدفوعة بالكامل',
  ),
);

/// سجلٌّ بكل الحالات، بأرقامٍ توضيحية تتّسق: طلبيةٌ بـ350 — دفعةٌ أُدخلت خطأً وأُلغيت، وعربونٌ
/// بحوالة، وتحصيلُ النورس بزائد دينار وتسوّى برسوم، ثم ردُّ 50: المدفوع 300 والمتبقي 50.
final _allStates = OrderLedger(
  payments: [
    OrderPayment(
      id: 11,
      orderId: 1311,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: '260.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      recordedBy: _farhat,
      paidAt: DateTime(2026, 10, 2, 10),
      isReversed: true,
      reversal: const OrderPaymentReversal(id: 12, reason: 'أُدخل المبلغ خطأ'),
      requiresReview: true,
      treasuryAccount: _office,
    ),
    OrderPayment(
      id: 12,
      orderId: 1311,
      type: OrderPaymentType.reversal,
      typeLabel: 'إلغاء قيد',
      amount: '260.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      recordedBy: _farhat,
      paidAt: DateTime(2026, 10, 2, 10, 5),
      notes: 'أُدخل المبلغ خطأ',
      reversesPaymentId: 11,
    ),
    OrderPayment(
      id: 13,
      orderId: 1311,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: '100.00',
      method: PaymentMethod.bankTransfer,
      methodLabel: 'حوالة',
      reference: '448120',
      hasReceipt: true,
      receiptIsImage: true,
      recordedBy: _mona,
      paidAt: DateTime(2026, 10, 2, 12),
      isReversible: true,
      requiresReview: true,
      canReview: true,
      treasuryAccount: _bank,
    ),
    OrderPayment(
      id: 14,
      orderId: 1311,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: '251.00',
      excessAmount: '1.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      recordedBy: _farhat,
      paidAt: DateTime(2026, 10, 6, 16),
      isReversible: true,
      requiresReview: true,
      isReviewed: true,
      reviewedBy: _sara,
      reviewedAt: DateTime(2026, 10, 7, 10, 30),
      canUnreview: true,
      treasuryAccount: _nawris,
      settlement: PaymentSettlement(
        operationId: 31,
        toAccount: _bank,
        fee: '10.00',
        received: '241.00',
        settledAt: DateTime(2026, 10, 7, 11),
        settledBy: _sara,
      ),
      canUnsettle: true,
    ),
    OrderPayment(
      id: 15,
      orderId: 1311,
      type: OrderPaymentType.refund,
      typeLabel: 'ردّ مبلغ',
      amount: '50.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      recordedBy: _farhat,
      paidAt: DateTime(2026, 10, 8, 9),
      requiresReview: true,
      canReview: true,
      treasuryAccount: _office,
    ),
  ],
  summary: const PaymentSummary(
    grandTotal: '350.00',
    paidAmount: '300.00',
    remainingAmount: '50.00',
    paymentStatus: PaymentStatus.partiallyPaid,
    paymentStatusLabel: 'مدفوعة جزئياً',
  ),
);

/// يفتح الصفحة فوق شاشةٍ أخرى، فيظهر زرّ الرجوع كما على الهاتف.
class _Launcher extends StatefulWidget {
  const _Launcher({required this.code});

  final String code;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderPaymentsPage(orderId: 1, orderCode: widget.code),
        ),
      ),
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

  if (Platform.environment['PREVIEW_ICONS'] case final material?) {
    await (FontLoader('MaterialIcons')..addFont(_bytes(material))).load();
  }
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(_loadFonts);

  testWidgets('draw «دفعات الطلبية»', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    debugDisableShadows = false;

    try {
      // لا `Injector.reset()`: الأداة تعمل في عزلٍ جديد لم يُسجَّل فيه شيء بعد.
      final cubit = _MockOrderPaymentsCubit();
      when(cubit.load).thenAnswer((_) async {});
      sl
        ..registerFactoryParam<OrderPaymentsCubit, int, void>((_, _) => cubit)
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
        );

      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      final theme = MaterialTheme(Typography.material2021().black.apply(fontFamily: 'Cairo'));

      Future<GlobalKey> draw({
        required OrderLedger ledger,
        required String code,
        bool dark = true,
        double height = 956,
      }) async {
        when(() => cubit.state).thenReturn(OrderPaymentsState.loaded(ledger: ledger));
        tester.view.physicalSize = Size(440 * 3, height * 3);

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
                home: _Launcher(code: code),
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

      await shoot(await draw(ledger: _order1307, code: '1307'), 'payments-1-order-1307');
      await shoot(
        await draw(ledger: _allStates, code: '1311', height: 1900),
        'payments-2-all-states',
      );

      final options = await draw(ledger: _allStates, code: '1311');
      await tester.ensureVisible(find.byKey(const ValueKey('options-14')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('options-14')));
      await tester.pumpAndSettle();
      await shoot(options, 'payments-3-options');

      await shoot(
        await draw(ledger: _order1307, code: '1307', dark: false),
        'payments-4-order-1307-light',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugDisableShadows = true;
    }
  });
}
