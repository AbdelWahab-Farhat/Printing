import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The order's own story: what happened, when, and — the part this file is about — who did it.
///
/// A note with nobody against it («تم الإلغاء — العميل غيّر رأيه») answers what and leaves the
/// only actionable question open. The API has always sent the name; the timeline just never
/// read it.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  OrderTransitionRecord move({
    String? from = 'قيد الطباعة',
    String to = 'جاهزة',
    String? reason,
    OrderActor? user,
  }) {
    return OrderTransitionRecord(
      id: to.hashCode,
      fromStatusLabel: from,
      toStatusLabel: to,
      reason: reason,
      user: user,
      createdAt: DateTime.utc(2026, 8, 5, 22, 18),
    );
  }

  testWidgets('a move says who made it, beside when', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderTimeline(
          records: [move(user: const OrderActor(id: 4, name: 'عبدالوهاب'))],
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — one line, because the time and the person are one fact.
    expect(find.textContaining('بواسطة عبدالوهاب'), findsOneWidget);
    expect(find.textContaining('أغسطس 2026'), findsOneWidget);
  });

  testWidgets('the note and the name are on the same entry', (tester) async {
    // Arrange — «Fuck off» in a workshop log is only useful if it says who wrote it.
    await tester.pumpWidget(
      host(
        OrderTimeline(
          records: [
            move(reason: 'العميل غيّر رأيه', user: const OrderActor(id: 7, name: 'سالم')),
          ],
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('العميل غيّر رأيه'), findsOneWidget);
    expect(find.textContaining('بواسطة سالم'), findsOneWidget);
  });

  testWidgets('a move with nobody behind it claims nobody', (tester) async {
    // Arrange — a seeder or a console command moves an order with no signed-in user, and the
    // column is nullable for exactly that.
    await tester.pumpWidget(host(OrderTimeline(records: [move()])));

    // Act
    await tester.pump();

    // Assert — the stamp is still there; no name is invented for it.
    expect(find.textContaining('بواسطة'), findsNothing);
    expect(find.textContaining('أغسطس 2026'), findsOneWidget);
  });

  testWidgets('the opening row reads as an event, not as a move out of nothing', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderTimeline(
          records: [
            move(from: null, to: 'جديدة', user: const OrderActor(id: 1, name: 'أحمد')),
          ],
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('تم إنشاء الطلبية'), findsOneWidget);
    expect(find.textContaining('بواسطة أحمد'), findsOneWidget);
  });
}
