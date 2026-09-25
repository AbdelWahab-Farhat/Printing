import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/get_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// الطلبية المفتوحة على شكل «أ · بطاقة الحالة» الذي اختاره صاحب العمل (٢٠٢٦-٠٩-٢٥): بطاقةٌ بلون
/// المرحلة فيها الخطوات الخمس، ثم المال، ثم البنود، ثم التسليم — والسؤال زرٌّ عائم.
///
/// الطلبية هنا هي #1304 كما هي في قاعدة البيانات يومها: ١٠٠ قطعة بـ1.72، و٦٠ كجم بـ36، إلى
/// طرابلس — الفلاح.
///
/// Arrange - Act - Assert throughout.
void main() {
  final year = DateTime.now().year;
  DateTime september(int day, [int hour = 12, int minute = 0]) =>
      DateTime(year, 9, day, hour, minute);

  const printed = OrderLine(
    id: 158,
    productName: 'أكياس يد خارجية - مطبوعه',
    variantLabel: '30*30',
    quantity: '100.000',
    pricingUnitLabel: 'قطعة',
    unitPrice: '1.720',
    lineTotal: '172.00',
  );
  const plain = OrderLine(
    id: 159,
    productName: 'أكياس يد خارجية - سادة',
    variantLabel: '50*50',
    quantity: '60.000',
    pricingUnitLabel: 'كجم',
    unitPrice: '36.000',
    lineTotal: '2160.00',
  );

  CustomerOrderDetail order1304({
    OrderStage stage = OrderStage.underReview,
    String stageLabel = 'بانتظار المراجعة',
    List<OrderTimelineEntry>? timeline,
    String? rejectionReason,
  }) => CustomerOrderDetail(
    id: 1304,
    code: '1304',
    stage: stage,
    stageLabel: stageLabel,
    rejectionReason: rejectionReason,
    cityName: 'طرابلس',
    regionName: 'الفلاح',
    recipientPhone: '0910000000',
    fulfilmentTypeLabel: 'توصيل',
    items: const [printed, plain],
    itemsTotal: '2332.00',
    deliveryPrice: '15.00',
    designFee: '0.00',
    discount: '0.00',
    total: '2332.00',
    paidAmount: '0.00',
    balance: '2332.00',
    timeline:
        timeline ??
        [
          OrderTimelineEntry(
            stage: 'under_review',
            stageLabel: 'بانتظار المراجعة',
            reachedAt: september(25, 14, 51),
          ),
        ],
    placedAt: september(25, 14, 51),
  );

  tearDown(() async {
    resetSnackBars();
    await sl.reset();
  });

  /// الطلبية فوق مسارٍ فيه الدعم، ليكون للزرّ العائم مكانٌ حقيقي يصل إليه.
  Future<void> open(WidgetTester tester, CustomerOrderDetail order) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final orders = _MockOrderRepository();
    when(() => orders.detail(any())).thenAnswer((_) async => Right(order));
    sl.registerFactoryParam<OrderDetailCubit, int, void>(
      (orderId, _) => OrderDetailCubit(orderId: orderId, get: GetOrder(orders)),
    );

    final router = GoRouter(
      initialLocation: '/orders/${order.id}',
      routes: [
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('الدعم عن ${state.uri.queryParameters['order']}')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the question', () {
    testWidgets('lives in a floating button, not a full-width one at the foot', (tester) async {
      // Arrange
      final order = order1304();

      // Act
      await open(tester, order);

      // Assert
      expect(find.widgetWithText(FloatingActionButton, 'اسأل عن الطلبية'), findsOneWidget);
      expect(find.text('لديك سؤال عن هذه الطلبية؟'), findsNothing);
    });

    testWidgets('opens support about this very order', (tester) async {
      // Arrange
      await open(tester, order1304());

      // Act
      await tester.tap(find.widgetWithText(FloatingActionButton, 'اسأل عن الطلبية'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الدعم عن 1304'), findsOneWidget);
    });
  });

  group('the stage card', () {
    testWidgets('names the stage once, and marks where the order stands', (tester) async {
      // Arrange
      final order = order1304(
        stage: OrderStage.producing,
        stageLabel: 'قيد الإنتاج',
        timeline: [
          OrderTimelineEntry(
            stage: 'under_review',
            stageLabel: 'بانتظار المراجعة',
            reachedAt: september(25, 14, 51),
          ),
          OrderTimelineEntry(stage: 'preparing', stageLabel: 'قيد التجهيز', reachedAt: september(26)),
          OrderTimelineEntry(stage: 'designing', stageLabel: 'قيد التصميم', reachedAt: september(27)),
          OrderTimelineEntry(stage: 'producing', stageLabel: 'قيد الإنتاج', reachedAt: september(28)),
        ],
      );

      // Act
      await open(tester, order);

      // Assert — «قيد التصميم» تُطوى في «التجهيز»، فيبقى تاريخ أول مرةٍ بلغتها الطلبية.
      expect(find.text('قيد الإنتاج'), findsOneWidget);
      expect(find.bySemanticsLabel('الخطوة 3 من 5: الإنتاج'), findsOneWidget);
      expect(find.text('25 سبتمبر'), findsOneWidget);
      expect(find.text('26 سبتمبر'), findsOneWidget);
      expect(find.text('27 سبتمبر'), findsNothing);
      expect(find.text('28 سبتمبر'), findsOneWidget);
    });

    testWidgets('shows no sentence under the stage — the steps say it', (tester) async {
      // Arrange
      final order = order1304().copyWith(stageHint: 'نراجع طلبيتك ونؤكّدها خلال ساعات العمل');

      // Act
      await open(tester, order);

      // Assert
      expect(find.text('نراجع طلبيتك ونؤكّدها خلال ساعات العمل'), findsNothing);
    });

    testWidgets('a delivered order has walked all five steps', (tester) async {
      // Arrange
      final order = order1304(stage: OrderStage.delivered, stageLabel: 'تم الاستلام');

      // Act
      await open(tester, order);

      // Assert
      expect(find.bySemanticsLabel('اكتملت الخطوات الخمس'), findsOneWidget);
    });

    testWidgets('a refused order draws no road, and says why', (tester) async {
      // Arrange
      final order = order1304(
        stage: OrderStage.rejected,
        stageLabel: 'مرفوضة',
        rejectionReason: 'المقاس غير متوفر حالياً',
      );

      // Act
      await open(tester, order);

      // Assert
      expect(find.text('المقاس غير متوفر حالياً'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^الخطوة')), findsNothing);
      expect(find.bySemanticsLabel('اكتملت الخطوات الخمس'), findsNothing);
    });
  });

  group('the money', () {
    testWidgets("puts the courier's fee under what is owed, never inside it", (tester) async {
      // Arrange
      final order = order1304();

      // Act
      await open(tester, order);

      // Assert — فوق «المتبقي» يجمعه القارئ إليه، والمندوب يأخذه على حسابه عند الباب.
      expect(find.text('2,332 د.ل'), findsNWidgets(2));
      expect(find.text('15 د.ل'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('التوصيل للمندوب')).dy,
        greaterThan(tester.getTopLeft(find.text('المتبقي')).dy),
      );
    });

    testWidgets('an order not yet priced says so instead of a figure', (tester) async {
      // Arrange
      final order = order1304().copyWith(
        isAwaitingQuote: true,
        total: null,
        paidAmount: null,
        balance: null,
      );

      // Act
      await open(tester, order);

      // Assert
      expect(find.text(awaitingQuoteLabel), findsOneWidget);
      expect(find.text('2,332 د.ل'), findsNothing);
    });
  });

  group('the lines', () {
    testWidgets('say how much of what, and what one of it costs', (tester) async {
      // Arrange
      final order = order1304();

      // Act
      await open(tester, order);

      // Assert — «1.72 × 100 د.ل» كانت تُقرأ مئة دينار، والكمية بلا وحدة.
      expect(find.text('100 قطعة'), findsOneWidget);
      expect(find.text('1.72 للقطعة'), findsOneWidget);
      expect(find.text('172 د.ل'), findsOneWidget);
      expect(find.text('60 كجم'), findsOneWidget);
      expect(find.text('36 للكجم'), findsOneWidget);
      expect(find.text('2,160 د.ل'), findsOneWidget);
    });
  });

  group('the order number', () {
    /// الرقم وحده عنواناً (طلب صاحب العمل، ٢٠٢٦-٠٩-٢٥): «طلبية» تقولها الشاشة كلها، و«#»
    /// زينةٌ لا تقول شيئاً.
    testWidgets('is the title alone, with no «طلبية» and no «#»', (tester) async {
      // Arrange
      final order = order1304();

      // Act
      await open(tester, order);

      // Assert
      final bar = find.byType(AppBar);
      expect(find.descendant(of: bar, matching: find.text('1304')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.textContaining('طلبية')), findsNothing);
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('is copied from the bar, for reading out on the phone', (tester) async {
      // Arrange — الحافظة قناةُ منصة لا وجود لها هنا، فيُلتقط ما أُرسل إليها.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }

        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester, order1304());

      // Act
      await tester.tap(find.byTooltip('نسخ رقم الطلبية'));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(copied, '1304');
      expect(find.text('تم نسخ رقم الطلبية'), findsOneWidget);

      resetSnackBars();
      await tester.pump();
    });
  });
}
