import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «كود النورس» على بطاقة الطلبية، والشيئان اللذان يجب ألّا يفعلهما.
///
/// **رقمُ الطرد عند الناقل هو ما يُقال في الهاتف** حين يسأل زبونٌ «فين طلبيتي؟»، وكان لا يُعرف
/// إلا بفتح الطلبية. وهو **ليس** «رقم التتبع»: ذاك خانةٌ يكتب فيها موظف، وهذا ما سمّى النورسُ به
/// الطرد — وطلبيةٌ واحدة قد تحمل الاثنين.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order orderWith({NawrisParcelRef? parcel, String? tracking}) => Order(
    id: 52,
    code: '1220',
    status: OrderStatus.outForDelivery,
    statusLabel: 'جاري التوصيل',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'زليتن',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '430.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '450.00',
    paidAmount: '150.00',
    remainingAmount: '300.00',
    nawrisParcel: parcel,
    trackingNumber: tracking,
  );

  Widget host(Order order) => ScreenUtilInit(
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
          child: SingleChildScrollView(child: OrderCard(order: order)),
        ),
      ),
    ),
  );

  testWidgets('the carrier code is on the card, without opening the order', (tester) async {
    // Arrange — the number a clerk needs when the phone rings.
    await tester.pumpWidget(host(orderWith(parcel: const NawrisParcelRef(code: '3702994'))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('كود النورس'), findsOneWidget);
    expect(find.text('3702994'), findsOneWidget);
  });

  testWidgets('an order that never went to a carrier grows no empty row', (tester) async {
    // Arrange — the common case, and the reason the row is conditional rather than blank.
    await tester.pumpWidget(host(orderWith()));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('كود النورس'), findsNothing);
  });

  testWidgets('it is not the tracking number, and the two stand together', (tester) async {
    // Arrange — one is typed by a person, the other is the carrier's own. An order can carry
    // both, and reading one out for the other sends a customer to the wrong shipment.
    await tester.pumpWidget(
      host(orderWith(parcel: const NawrisParcelRef(code: '3702994'), tracking: 'TN-88')),
    );

    // Act
    await tester.pump();

    // Assert — the card shows the carrier's code; the typed one is the details screen's.
    expect(find.text('3702994'), findsOneWidget);
    expect(find.text('كود النورس'), findsOneWidget);
  });
}
