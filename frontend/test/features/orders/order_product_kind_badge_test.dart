import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_flow.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مطبوع» / «سادة» / «تصنيع» on the list card, beside the status band.
///
/// Read off the road the server stamped, so it holds from creation to settlement.
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

  Order orderWith(
    OrderFlow flow, {
    OrderStatus status = OrderStatus.taken,
    String statusLabel = 'جديدة',
    DateTime? deletedAt,
    bool urgent = false,
    bool partiallyDelivered = false,
    bool compensation = false,
  }) => Order(
    id: 52,
    code: '1239',
    status: status,
    statusLabel: statusLabel,
    isFinal: false,
    isUrgent: urgent,
    isPartiallyDelivered: partiallyDelivered,
    isCompensation: compensation,
    productionFlow: flow,
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

  const kinds = {
    OrderFlow.standard: 'مطبوع',
    OrderFlow.noProduction: 'سادة',
    OrderFlow.outsourced: 'تصنيع',
  };

  for (final MapEntry(key: flow, value: word) in kinds.entries) {
    testWidgets('a ${flow.name} order reads «$word» beside its status', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderCard(order: orderWith(flow))));

      // Act - Assert — the status band is still there and still says the status.
      expect(find.text(word), findsOneWidget);
      expect(tester.widget<OrderStatusChip>(find.byType(OrderStatusChip)).label, 'جديدة');
    });
  }

  testWidgets('an unknown road shows no kind rather than a guess', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(OrderFlow.unknown))));

    // Act - Assert
    for (final word in kinds.values) {
      expect(find.text(word), findsNothing);
    }
  });

  testWidgets('the kind stays on a settled order', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            OrderFlow.noProduction,
            status: OrderStatus.settled,
            statusLabel: 'تم التسوية',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.text('سادة'), findsOneWidget);
  });

  testWidgets('the kind costs the list no height', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(OrderFlow.unknown))));
    final bare = tester.getSize(find.byType(OrderCard)).height;

    // Act
    await tester.pumpWidget(host(OrderCard(order: orderWith(OrderFlow.standard))));
    final badged = tester.getSize(find.byType(OrderCard)).height;

    // Assert — it shares the status band's own row.
    expect(badged, bare);
  });

  // The widest word, on the busiest status, next to each of the other badges in turn.
  final neighbours = <String, Order Function()>{
    'deleted': () => orderWith(
      OrderFlow.outsourced,
      status: OrderStatus.outForDelivery,
      statusLabel: 'جاري التوصيل',
      deletedAt: DateTime.utc(2026, 9, 20),
    ),
    'urgent': () => orderWith(
      OrderFlow.outsourced,
      status: OrderStatus.outForDelivery,
      statusLabel: 'جاري التوصيل',
      urgent: true,
    ),
    'partly collected': () => orderWith(
      OrderFlow.outsourced,
      status: OrderStatus.outForDelivery,
      statusLabel: 'جاري التوصيل',
      partiallyDelivered: true,
    ),
    'compensation': () => orderWith(
      OrderFlow.outsourced,
      status: OrderStatus.outForDelivery,
      statusLabel: 'جاري التوصيل',
      compensation: true,
    ),
  };

  for (final MapEntry(key: name, value: order) in neighbours.entries) {
    testWidgets('beside a $name badge it fits on the narrowest phone', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Act
      await tester.pumpWidget(host(OrderCard(order: order())));

      // Assert — both are readable and nothing runs off the edge of the card.
      expect(find.text('تصنيع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('beside two other badges it yields its place on the card', (tester) async {
    // Arrange — a deleted, partly collected order: the row this badge would push off a phone.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            OrderFlow.outsourced,
            status: OrderStatus.outForDelivery,
            statusLabel: 'جاري التوصيل',
            deletedAt: DateTime.utc(2026, 9, 20),
            partiallyDelivered: true,
          ),
        ),
      ),
    );

    // Assert — the other two keep the row as they had it before this badge existed.
    expect(find.text('تصنيع'), findsNothing);
    expect(find.text('محذوفة'), findsOneWidget);
    expect(find.text('استلام جزئي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
