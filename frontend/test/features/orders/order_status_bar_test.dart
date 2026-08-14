import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_bar.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the order is, said once and said loudly.
///
/// The detail screen used to answer that with a chip the size of the one on a list row, sharing
/// a line with the total. It is the question the screen is opened for, so it gets the width.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into, at a known width so a full-width claim can be measured.
  Widget host(Widget child, {double width = 430}) {
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
            child: Center(child: SizedBox(width: width, child: child)),
          ),
        ),
      ),
    );
  }

  testWidgets('the bar takes every pixel it is offered', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        const OrderStatusBar(status: OrderStatus.delivered, label: 'تم الاستلام'),
        width: 400,
      ),
    );

    // Act
    await tester.pump();

    // Assert — a chip that shrink-wraps its word is what this replaced.
    expect(tester.getSize(find.byType(OrderStatusBar)).width, 400);
  });

  testWidgets('a glyph stands beside the name', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(const OrderStatusBar(status: OrderStatus.outForDelivery, label: 'قيد التوصيل')),
    );

    // Act
    await tester.pump();

    // Assert — read before the word is, which is the whole point of it being there.
    expect(find.byType(Icon), findsOneWidget);
    expect(find.text('قيد التوصيل'), findsOneWidget);
  });

  testWidgets('the name is set larger than the same status on a list row', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            OrderStatusBar(status: OrderStatus.ready, label: 'جاهزة'),
            OrderStatusChip(status: OrderStatus.ready, label: 'جاهزة'),
          ],
        ),
      ),
    );

    // Act
    await tester.pump();
    final onBar = tester.widget<Text>(find.text('جاهزة').first);
    final onChip = tester.widget<Text>(find.text('جاهزة').last);

    // Assert
    expect(onBar.style?.fontSize, greaterThan(onChip.style!.fontSize!));
  });

  testWidgets('a status this build has never heard of still reads correctly', (tester) async {
    // Arrange — the label came with it from the server; only the colour and the glyph fall back.
    await tester.pumpWidget(
      host(const OrderStatusBar(status: OrderStatus.unknown, label: 'قيد المراجعة')),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
