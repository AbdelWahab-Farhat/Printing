import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «المورد» in the order's own bar, beside the customer and the destination.
///
/// **The snapshot, never a lookup.** `vendor_name` is what this order said on the day; a vendor
/// renamed since keeps the new name everywhere except here, which is the whole reason the
/// column exists. And on an order we make ourselves the line is not drawn at all — a header
/// that said «المورد: —» on every printed job would be a row nobody reads.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({String? vendorName}) => Order(
    id: 1,
    code: '1',
    status: OrderStatus.manufacturing,
    statusLabel: 'قيد التصنيع',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '2500.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '2500.00',
    vendorId: vendorName == null ? null : 4,
    vendorName: vendorName,
  );

  Widget host(Widget headerSliver) {
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
          body: CustomScrollView(
            slivers: [headerSliver, const SliverToBoxAdapter(child: SizedBox(height: 1200))],
          ),
        ),
      ),
    );
  }

  testWidgets('a وسيط order names who is making it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order(vendorName: 'مطبعة الأمل'))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('المورد: مطبعة الأمل'), findsOneWidget);
  });

  testWidgets('an order we make ourselves says nothing about a vendor', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order())));

    // Act
    await tester.pump();

    // Assert
    expect(find.textContaining('المورد'), findsNothing);
  });
}
