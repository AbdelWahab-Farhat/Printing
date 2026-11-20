import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «رقم المندوب» and «رسالة المندوب» on the order card.
///
/// The phone arrives from Nawris once a courier takes the parcel; the message — invoice number,
/// phone and parcel code — is written by the server and only copied here.
/// See Docs/nawris/NAWRIS-INTEGRATION.md §5.5.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order orderWith({
    NawrisParcelRef? parcel,
    String? tracking,
    String? phone,
    String? message,
  }) => Order(
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
    courierPhone: phone,
    courierMessageText: message,
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

  const message = 'طلبيتك رقم الفاتورة : [ 1220 ]\nرقم المندوب : 0944112145\nكود الشحنة : 3702994';

  testWidgets('the courier phone stands beside the carrier code', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        orderWith(
          parcel: const NawrisParcelRef(code: '3702994'),
          phone: '0944112145',
          message: message,
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('كود النورس'), findsOneWidget);
    expect(find.text('رقم المندوب'), findsOneWidget);
    expect(find.text('0944112145'), findsOneWidget);
    expect(find.text('رسالة المندوب'), findsOneWidget);
  });

  testWidgets('the button copies the server text', (tester) async {
    // Arrange
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }

      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      host(
        orderWith(
          parcel: const NawrisParcelRef(code: '3702994'),
          phone: '0944112145',
          message: message,
        ),
      ),
    );
    await tester.pump();

    // Act
    await tester.tap(find.byTooltip('نسخ رسالة المندوب'));
    await tester.pump();

    // Assert
    expect(copied, message);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('before a courier takes it, the code shows alone', (tester) async {
    // Arrange — lodged with Nawris, no courier yet: no phone, no text from the server.
    await tester.pumpWidget(host(orderWith(parcel: const NawrisParcelRef(code: '3702994'))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('3702994'), findsOneWidget);
    expect(find.text('رقم المندوب'), findsNothing);
    expect(find.byTooltip('نسخ رسالة المندوب'), findsNothing);
  });

  testWidgets('a closed order keeps the phone but loses the button', (tester) async {
    // Arrange — the server stops sending the text once the customer has the bags.
    await tester.pumpWidget(
      host(orderWith(parcel: const NawrisParcelRef(code: '3702994'), phone: '0944112145')),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('0944112145'), findsOneWidget);
    expect(find.byTooltip('نسخ رسالة المندوب'), findsNothing);
  });

  testWidgets('another carrier: the typed tracking number is the code', (tester) async {
    // Arrange — dispatched by hand, with the courier's phone typed at «جاري التوصيل».
    await tester.pumpWidget(
      host(orderWith(tracking: 'TN-88', phone: '0913334444', message: message)),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('رقم التتبع'), findsOneWidget);
    expect(find.text('TN-88'), findsOneWidget);
    expect(find.text('0913334444'), findsOneWidget);
    expect(find.byTooltip('نسخ رسالة المندوب'), findsOneWidget);
  });
}
