import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_card.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// بطاقة «طلباتي» على شكل بطاقة تطبيق الموظفين (طلب المستخدم، 2026-09-25): شريط المرحلة
/// بأيقونتها أعلاها، ثم ثلاثة صفوفٍ من ثلاث خانات، ثم بنود الطلبية في ذيلها.
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

  testWidgets('the stage runs across the top of the card, with its icon', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    final banner = find.byType(StageBanner);
    expect(banner, findsOneWidget);
    expect(find.descendant(of: banner, matching: find.text('قيد الإنتاج')), findsOneWidget);
    expect(
      find.descendant(of: banner, matching: find.byIcon(stageIcon(OrderStage.producing))),
      findsOneWidget,
    );
  });

  testWidgets('each cell names what it holds, above it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));

    // Act
    await tester.pumpAndSettle();

    // Assert
    for (final (label, value) in [
      ('رقم الطلبية', '#1228'),
      ('رقم الاستلام', '0913333333'),
      ('سعر الطلبية', '245 د.ل'),
      ('المدفوع', '100 د.ل'),
      ('المتبقي', '145 د.ل'),
      ('مكان الاستلام', 'بنغازي'),
      ('التسليم', 'توصيل'),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.text('تاريخ الطلب'), findsOneWidget);
  });

  /// كما في بطاقة الموظفين: الأحمر ما دام شيءٌ مستحقاً، والأخضر حين لا شيء — صفرٌ بأحمر الإنذار
  /// يجعل الطلبية المسدّدة تبدو هي المشكلة.
  testWidgets('what is still owed is red, and green once nothing is', (tester) async {
    // Arrange
    await tester.pumpWidget(host(priced));
    await tester.pumpAndSettle();
    final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

    // Act
    final owed = tester.widget<Text>(find.text('145 د.ل')).style?.color;
    await tester.pumpWidget(host(priced.copyWith(balance: '0.00')));
    await tester.pumpAndSettle();
    final settled = tester.widget<Text>(find.text('0 د.ل')).style?.color;

    // Assert
    expect(owed, scheme.error);
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

  testWidgets('the lines sit under the cells: two, and the rest behind «عرض الكل»', (
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
    await tester.tap(find.text('رقم الطلبية'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('طلبية 7'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
