import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:printing/features/customers/presentation/widgets/customer_orders_section.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/models/orders_filter.dart';

/// «إدارة الطلبات» on the customer screen — three ways into one person's orders.
///
/// **What is worth proving is that each row opens what its label promises.** A row reading
/// «الطلبات المستلمة» that opens the whole shop's orders is the failure this section exists to
/// avoid, and it is invisible to anybody reading the screen.
///
/// Arrange - Act - Assert throughout.
void main() {
  const counts = OrderCounts(
    byStatus: {'new': 2, 'out_for_delivery': 3, 'delivered': 8, 'settled': 5, 'cancelled': 4},
    total: 22,
  );

  late List<OrdersFilter> opened;

  setUp(() => opened = <OrdersFilter>[]);

  Widget host({CustomerOrderCountsState? state}) => ScreenUtilInit(
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
        body: SingleChildScrollView(
          child: CustomerOrdersSection(
            customerId: 7,
            customerName: 'مطبعة النور',
            state: state ?? const CustomerOrderCountsState.loaded(counts),
            onOpen: opened.add,
          ),
        ),
      ),
    ),
  );

  testWidgets('it offers the three ways in', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('كل طلبات العميل'), findsOneWidget);
    expect(find.text('الطلبات الجارية'), findsOneWidget);
    expect(find.text('الطلبات المستلمة'), findsOneWidget);
  });

  testWidgets('each row carries its own number', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — 22 in total, 5 still moving (2 new + 3 out for delivery), 13 arrived.
    expect(find.text('22'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('«كل طلبات العميل» asks for this customer and no status', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('كل طلبات العميل'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened.single.customerId, 7);
    expect(opened.single.statuses, isEmpty, reason: 'كل means every status, cancellations too');
  });

  testWidgets('«الطلبات الجارية» asks for every unfinished status', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('الطلبات الجارية'));
    await tester.pumpAndSettle();

    // Assert — the same group the number above it was added up from, or the tap contradicts
    // the count beside it.
    expect(opened.single.customerId, 7);
    expect(opened.single.statuses, OrderStatus.inProgress.map((s) => s.wire).toList());
  });

  testWidgets('«الطلبات المستلمة» asks for delivered and settled', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('الطلبات المستلمة'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened.single.customerId, 7);
    expect(opened.single.statuses, ['delivered', 'settled']);
  });

  testWidgets('the screen each row opens says whose orders it is showing', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('الطلبات الجارية'));
    await tester.pumpAndSettle();

    // Assert — the title travels with the filter because the destination has no other way to
    // name the customer: it was handed an id, not a person.
    expect(opened.single.title, contains('مطبعة النور'));
  });

  testWidgets('counts that could not be read leave the rows open and bare', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(state: const CustomerOrderCountsState.loading()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الطلبات الجارية'));
    await tester.pumpAndSettle();

    // Assert — reaching a customer's orders must not depend on having counted them first.
    expect(opened, hasLength(1));
  });
}
