import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «محذوفة» على بطاقة القائمة، بجانب شريط الحالة لا بدلاً منه.
///
/// الطلبية المحذوفة تبقى على الحالة التي حُذفت عليها، فالشريط وحده كان يقول «جاري التوصيل» عن
/// طلبيةٍ خرجت من المحل.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget card) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  Order orderWith({
    DateTime? deletedAt,
    bool urgent = false,
    bool? partiallyDelivered,
  }) => Order(
    id: 52,
    code: '1239',
    status: OrderStatus.outForDelivery,
    statusLabel: 'جاري التوصيل',
    isFinal: false,
    isUrgent: urgent,
    isPartiallyDelivered: partiallyDelivered,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'البيضاء',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '700.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '700.00',
    paidAmount: '0.00',
    remainingAmount: '700.00',
    deletedAt: deletedAt,
  );

  final deleted = DateTime.utc(2026, 9, 20);

  testWidgets('a deleted order says so beside its state', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCard(order: orderWith(deletedAt: deleted))),
    );

    // Act - Assert — the state it was deleted at is still the one on the band.
    expect(find.text('محذوفة'), findsOneWidget);
    expect(
      tester.widget<OrderStatusChip>(find.byType(OrderStatusChip)).label,
      'جاري التوصيل',
    );
  });

  testWidgets('an order in the shop carries no such badge', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('محذوفة'), findsNothing);
  });

  testWidgets('the badge costs the list no height', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));
    final plain = tester.getSize(find.byType(OrderCard)).height;

    // Act
    await tester.pumpWidget(
      host(OrderCard(order: orderWith(deletedAt: deleted))),
    );
    final badged = tester.getSize(find.byType(OrderCard)).height;

    // Assert — it shares the status band's own row.
    expect(badged, plain);
  });

  testWidgets('a deleted order is no longer urgent', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCard(order: orderWith(deletedAt: deleted, urgent: true))),
    );

    // Act - Assert — «محذوفة» takes «مستعجل»'s place rather than a place beside it.
    expect(find.text('محذوفة'), findsOneWidget);
    expect(find.text('مستعجل'), findsNothing);
  });

  testWidgets(
    'a deleted, partly collected order fits beside the status on the narrowest phone',
    (tester) async {
      // Arrange — the widest the row can get.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Act
      await tester.pumpWidget(
        host(
          OrderCard(
            order: orderWith(
              deletedAt: deleted,
              urgent: true,
              partiallyDelivered: true,
            ),
          ),
        ),
      );

      // Assert — both badges are readable, and nothing runs off the edge of the card.
      expect(find.text('محذوفة'), findsOneWidget);
      expect(find.text('استلام جزئي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
