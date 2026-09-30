import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_card.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_progress_bar.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/size_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// بطاقة «طلباتي» بلغة تطبيق العميل (اتجاه «أ · الخطوات»، اختاره المستخدم، 2026-09-25): المرحلة
/// في مربّعٍ بلونها ورقم الطلبية بجانبها، ثم الخطوات الخمس، ثم المال في ثلاث خانات، ثم المدينة
/// والهاتف، ثم البنود. **ولا «التسليم»**: قال المستخدم إنه غير ضروري.
///
/// Arrange - Act - Assert throughout.
void main() {
  OrderLine line(int id, String name) => OrderLine(
    id: id,
    productName: name,
    variantLabel: '30*40',
    quantity: '500.000',
    pricingUnitLabel: 'قطعة',
  );

  final priced = CustomerOrder(
    id: 7,
    code: '1228',
    stage: OrderStage.producing,
    stageLabel: 'قيد الإنتاج',
    total: '245.000',
    paidAmount: '100.000',
    balance: '145.00',
    cityName: 'بنغازي',
    recipientPhone: '0913333333',
    fulfilmentTypeLabel: 'توصيل',
    placedAt: DateTime.now(),
    items: [line(1, 'أكياس شحن - مطبوعة')],
  );

  Widget host(CustomerOrder order) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [OrderCard(order: order)],
            ),
          ),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('طلبية ${state.pathParameters['id']}')),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
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
    );
  }

  /// لون المبلغ المرسوم: الرقم وعملته نصٌّ واحد، واللون على جزء الرقم منه.
  Color? figureColour(WidgetTester tester, String text) {
    final span = tester.widget<Text>(find.text(text)).textSpan! as TextSpan;

    return span.style?.color;
  }

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('the stage leads the card: its icon on a tile of its colour, its word beside it', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;
    final tile = find.byType(StageTile);
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.byIcon(stageIcon(OrderStage.producing))),
      findsOneWidget,
    );
    final fill = tester.widget<Container>(
      find.descendant(of: tile, matching: find.byType(Container)).first,
    );
    expect(
      (fill.decoration! as BoxDecoration).color,
      stageTone(scheme, OrderStage.producing).background,
    );
    expect(find.text('قيد الإنتاج'), findsOneWidget);
  });

  testWidgets('the number sits bare in the header, with the day under the stage', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('1228'), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.byIcon(AppIcons.forward), findsOneWidget);
  });

  testWidgets('an order under way shows the five steps, standing on its own', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    final bar = find.byType(OrderProgressBar);
    expect(bar, findsOneWidget);
    expect(tester.widget<OrderProgressBar>(bar).step, OrderStep.producing);
  });

  testWidgets('a finished order has no steps left to show', (tester) async {
    // Arrange
    final delivered = priced.copyWith(stage: OrderStage.delivered, stageLabel: 'تم الاستلام');

    // Act
    await tester.pumpWidget(host(delivered));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(OrderProgressBar), findsNothing);
    expect(find.text('تم الاستلام'), findsOneWidget);
  });

  testWidgets('the money is three figures, each named above it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    for (final (label, value) in [
      ('سعر الطلبية', '245 د.ل'),
      ('المدفوع', '100 د.ل'),
      ('المتبقي', '145 د.ل'),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
      expect(find.text(value), findsOneWidget, reason: value);
      expect(
        tester.getTopLeft(find.text(label)).dy,
        lessThan(tester.getTopLeft(find.text(value)).dy),
        reason: '$label above its figure',
      );
    }
  });

  /// كصفحة الطلبية المفتوحة: المستحق برتقالي العلامة لا أحمر الإنذار — مالٌ على طلبيةٍ تسير جيداً
  /// ليس خطأً — والصفر أخضر: الطلبية مسدّدة.
  testWidgets('what is still owed is in the brand orange, and green once nothing is', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));
    await tester.pumpAndSettle();
    final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

    // Act
    final owed = figureColour(tester, '145 د.ل');
    final paid = figureColour(tester, '100 د.ل');
    await tester.pumpWidget(host(priced.copyWith(balance: '0.00')));
    await tester.pumpAndSettle();
    final settled = figureColour(tester, '0 د.ل');

    // Assert
    expect(owed, scheme.primary);
    expect(paid, scheme.paid);
    expect(settled, scheme.paid);
  });

  testWidgets('an order still to be priced says so, and leaves paid and owed blank', (
    tester,
  ) async {
    // Arrange
    final unpriced = priced.copyWith(
      total: null,
      paidAmount: null,
      balance: null,
      isAwaitingQuote: true,
    );

    // Act
    await tester.pumpWidget(host(unpriced));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('يُحدَّد بعد المراجعة'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('where it goes and who takes it: the city by a pin, the number by a phone', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('بنغازي'), findsOneWidget);
    expect(find.text('0913333333'), findsOneWidget);
    expect(find.byIcon(AppIcons.mapPin), findsOneWidget);
    expect(find.byIcon(AppIcons.phone), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('0913333333')).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('with neither a city nor a number, that row is not drawn', (tester) async {
    // Arrange
    final nowhere = priced.copyWith(cityName: null, recipientPhone: null);

    // Act
    await tester.pumpWidget(host(nowhere));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byIcon(AppIcons.mapPin), findsNothing);
    expect(find.byIcon(AppIcons.phone), findsNothing);
    expect(find.text('—'), findsNothing);
  });

  /// «التسليم غير ضروري» (المستخدم، 2026-09-25) — وخانات الموظف بأسمائها ذهبت معه.
  testWidgets('how it is handed over is not on the card, nor the staff card cell names', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    for (final gone in ['التسليم', 'توصيل', 'رقم الطلبية', 'رقم الاستلام', 'مكان الاستلام']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    expect(find.text('تاريخ الطلب'), findsNothing);
  });

  testWidgets('each line carries its size in a chip and its quantity with its unit', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    final chip = find.byType(SizeChip);
    expect(chip, findsOneWidget);
    expect(find.descendant(of: chip, matching: find.text('30*40')), findsOneWidget);
    expect(find.text('أكياس شحن - مطبوعة'), findsOneWidget);
    expect(find.text('500 قطعة'), findsOneWidget);
  });

  testWidgets('the lines sit at the foot: two, and the rest behind «عرض الكل»', (
    tester,
  ) async {
    // Arrange
    final three = priced.copyWith(
      items: [line(1, 'أكياس شحن'), line(2, 'أكياس يد'), line(3, 'أكياس شفافة')],
    );
    await tester.pumpWidget(host(three));
    await tester.pumpAndSettle();
    expect(find.text('أكياس شفافة'), findsNothing);

    // Act
    await tester.tap(find.text('عرض الكل (3)'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أكياس شحن'), findsOneWidget);
    expect(find.text('أكياس يد'), findsOneWidget);
    expect(find.text('أكياس شفافة'), findsOneWidget);
    expect(find.text('إخفاء'), findsOneWidget);
  });

  testWidgets('tapping the card opens the order, with a way back', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('1228'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('طلبية 7'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
