import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of the orders list.
///
/// The card carried «سعر الطلبية» alone for as long as the server had nothing else to say about
/// it. It says three things now, and the point of these tests is that all three are **printed as
/// sent** — a card that subtracted its own «المتبقي» would be a second answer to a question the
/// server already answered, and its answer would be the one made of doubles.
///
/// **والباقي هنا عن الشكل الذي طُلب نسخه من بطاقة بريمولا:** الحالة شريطٌ يملأ أعلى البطاقة، ولا
/// تلوين للبطاقة نفسها، ولا شارة دفع، ولا خطوط فاصلة — الأرقام الثلاثة تقول ما كانت الشارة تقوله.
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
    String paid = '150.00',
    String remaining = '300.00',
    PaymentStatus paymentStatus = PaymentStatus.partiallyPaid,
    String paymentLabel = 'مدفوعة جزئياً',
  }) {
    return Order(
      id: 52,
      code: '52',
      status: OrderStatus.delivered,
      statusLabel: 'تم الاستلام',
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
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: paymentStatus,
      paymentStatusLabel: paymentLabel,
    );
  }

  testWidgets('the three money figures sit on the card, each under its own name', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('سعر الطلبية'), findsOneWidget);
    expect(find.text('المدفوع'), findsOneWidget);
    expect(find.text('المتبقي'), findsOneWidget);

    expect(find.text('450'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
  });

  testWidgets('nothing is recomputed — the strings arrive rendered as they were sent', (
    tester,
  ) async {
    // Arrange — a remaining amount that disagrees with the subtraction, which is what an
    // overpaid order looks like. The card must show what it was handed.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            paid: '500.00',
            remaining: '-50.00',
            paymentStatus: PaymentStatus.overpaid,
            paymentLabel: 'مدفوعة بالزيادة',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.text('-50'), findsOneWidget);
  });

  testWidgets('the status is a band across the top, not a chip in a corner', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act
    final card = tester.getSize(find.byType(OrderCard));
    final band = tester.getSize(find.byType(OrderStatusChip));

    // Assert — the whole width of the card less its own padding, the way the reference card
    // wears its state, with the status's own glyph beside the word.
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(band.width, greaterThan(card.width * 0.9));
    expect(find.byIcon(OrderStatusChip.iconFor(OrderStatus.delivered)), findsOneWidget);

    // …and the glyph closes the band rather than opening it: in an Arabic layout the end of a
    // line is its left, which is where the reference card puts it.
    final glyph = tester.getCenter(find.byIcon(OrderStatusChip.iconFor(OrderStatus.delivered)));
    expect(glyph.dx, lessThan(tester.getCenter(find.text('تم الاستلام')).dx));
  });

  testWidgets('no payment chip — the three figures already answer it', (tester) async {
    // Arrange — «مدفوعة جزئياً» said nothing that «المدفوع» و«المتبقي» beneath it do not.
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('مدفوعة جزئياً'), findsNothing);
  });

  testWidgets('the name is the bold half of a cell, the figure the quiet one', (tester) async {
    // Arrange — البطاقة المرجعية تكتب العنوان عريضاً وأكبر، والقيمة تحته أهدأ منه. كان عندنا
    // العكس: عنوانٌ رمادي صغير وقيمة سوداء عريضة.
    await tester.pumpWidget(host(OrderCard(order: orderWith())));
    final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

    // Act
    final label = tester.widget<Text>(find.text('رقم الفاتورة')).style!;
    final value = tester.widget<Text>(find.text('#52')).style!;

    // Assert
    expect(label.fontWeight, FontWeight.w800);
    expect(label.fontSize, greaterThan(value.fontSize!));
    expect(label.color, scheme.onSurface);
    // …and the value is dark too, not the muted grey it was: at a third of a phone's width it
    // was the faintest thing on a card whose whole job is to be read at a glance.
    expect(value.color, scheme.onSurface);
  });

  group('the money wears its own colours', () {
    testWidgets('price, paid and remaining are each coloured for what they are', (tester) async {
      // Arrange — رقمٌ بلا لون بين تسعة أرقام لا يُقرأ إلا بقراءة عنوانه.
      await tester.pumpWidget(host(OrderCard(order: orderWith())));
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Act
      final price = tester.widget<Text>(find.text('450')).style!;
      final paid = tester.widget<Text>(find.text('150')).style!;
      final remaining = tester.widget<Text>(find.text('300')).style!;

      // Assert
      expect(price.color, scheme.primary);
      expect(paid.color, scheme.paid);
      expect(remaining.color, scheme.error);
    });

    testWidgets('nothing owed is green, not red — a zero is not a problem', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderCard(
            order: orderWith(
              paid: '450.00',
              remaining: '0.00',
              paymentStatus: PaymentStatus.paid,
              paymentLabel: 'مدفوعة بالكامل',
            ),
          ),
        ),
      );
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Act
      final remaining = tester.widget<Text>(find.text('0')).style!;

      // Assert
      expect(remaining.color, scheme.paid);
      expect(remaining.color, isNot(scheme.error));
    });
  });

  group('lifting a value off the card', () {
    testWidgets('the text is selectable — the copy menu is the phone\'s own', (tester) async {
      // Arrange — نسخٌ بضغطة مطوّلة من صنعنا كان اختراعاً: التحديد والنسخ حركة يعرفها صاحب
      // الهاتف أصلاً، وهي وحدها التي تسمح بنسخ نصف رقم أو خانتين معاً.
      await tester.pumpWidget(host(OrderCard(order: orderWith())));

      // Act - Assert
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('nothing is copied behind the user\'s back', (tester) async {
      // Arrange
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }

        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(host(OrderCard(order: orderWith())));

      // Act — الضغطة المطوّلة صارت للتحديد، لا لنسخ الخانة كاملة من وراء صاحبها.
      await tester.longPress(find.text('#52'));
      await tester.pump();

      // Assert
      expect(copied, isEmpty);
    });

    testWidgets('a tap on a value still opens the order', (tester) async {
      // Arrange — «يضغطوا على أي مكان ويدخلوا الطلبية»: التحديد لا يأخذ الضغطة القصيرة.
      var opened = 0;
      await tester.pumpWidget(host(OrderCard(order: orderWith(), onTap: () => opened++)));

      // Act
      await tester.tap(find.text('#52'));
      await tester.pump();

      // Assert
      expect(opened, 1);
    });

    testWidgets('and a tap on the space between a name and its value opens it too', (
      tester,
    ) async {
      // Arrange — البطاقة تُضغط كبطاقة، لا كتسع كلمات متفرّقة: الفراغ بين العنوان وقيمته جزء
      // من الصفّ الذي يُفتح، لا ثقبٌ فيه.
      var opened = 0;
      await tester.pumpWidget(host(OrderCard(order: orderWith(), onTap: () => opened++)));
      final label = tester.getRect(find.text('رقم الفاتورة'));
      final value = tester.getRect(find.text('#52'));

      // Act
      await tester.tapAt(Offset(label.center.dx, (label.bottom + value.top) / 2));
      await tester.pump();

      // Assert
      expect(opened, 1);
    });
  });

  testWidgets('no rules between the rows', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert — the rows are held apart by space alone.
    expect(find.byType(Divider), findsNothing);
  });

  group('the card that is paid for', () {
    /// The surface the card actually draws — the `Material` the whole row sits on.
    Color surfaceOf(WidgetTester tester) {
      return tester
          .widget<Material>(
            find.descendant(of: find.byType(OrderCard), matching: find.byType(Material)).first,
          )
          .color!;
    }

    testWidgets('a settled order is not tinted — no card wears a wash', (tester) async {
      // Arrange — the green wash read as a highlight on a queue nobody asked to have
      // highlighted; «المتبقي: 0.00» is the same news, quietly.
      await tester.pumpWidget(
        host(
          OrderCard(
            order: orderWith(
              paid: '450.00',
              remaining: '0.00',
              paymentStatus: PaymentStatus.paid,
              paymentLabel: 'مدفوعة بالكامل',
            ),
          ),
        ),
      );

      // Act
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Assert
      expect(surfaceOf(tester), scheme.surfaceContainerLowest);
    });

    testWidgets('every other payment state keeps the same plain card', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderCard(order: orderWith())));

      // Act
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Assert
      expect(surfaceOf(tester), scheme.surfaceContainerLowest);
    });
  });
}
