import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/presentation/widgets/ready_message_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «بانتظار رسالة الجاهزية» — صندوق الطابور على الشاشة الرئيسية.
///
/// **صندوقٌ واحدٌ عريض لا بطاقةٌ في لوحة**، لأنّه طابور عملٍ يخصّ شخصاً بعينه لا قسمةً لطلبيات
/// الورشة على محاورها — انظر ORDER-READY-MESSAGE.md §٦. ومن لا يملك الصلاحية لا يصل إليه أصلاً:
/// الخادم يحذف المفتاح، فلا يجد `HomePage` ما يبنيه.
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

  const queue = ReadyMessageQueue(count: 7, label: 'بانتظار رسالة الجاهزية');

  testWidgets('it prints the number and the server\'s own word', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ReadyMessageBox(queue: queue)));

    // Act - Assert — the label is never translated here: the screen the box opens is titled with
    // the box's own word, and this app holds no table of them.
    expect(find.text('بانتظار رسالة الجاهزية'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('tapping it opens the queue', (tester) async {
    // Arrange
    var opened = false;
    await tester.pumpWidget(host(ReadyMessageBox(queue: queue, onOpen: () => opened = true)));

    // Act
    await tester.tap(find.byType(ReadyMessageBox));
    await tester.pumpAndSettle();

    // Assert
    expect(opened, isTrue);
  });

  testWidgets('a box counting nothing stays drawn and refuses the tap', (tester) async {
    // Arrange — «لا شيء ينتظر» is an answer worth reading every morning, and opening an empty
    // screen is a tap that teaches the reader nothing they cannot already see.
    var opened = false;
    await tester.pumpWidget(
      host(
        ReadyMessageBox(
          queue: const ReadyMessageQueue(count: 0, label: 'بانتظار رسالة الجاهزية'),
          onOpen: () => opened = true,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(ReadyMessageBox));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('بانتظار رسالة الجاهزية'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(opened, isFalse);
  });

  testWidgets('a box with nowhere to go is readable and inert', (tester) async {
    // Arrange — no callback at all, the way every other card on this screen behaves.
    await tester.pumpWidget(host(const ReadyMessageBox(queue: queue)));

    // Act
    await tester.tap(find.byType(ReadyMessageBox));
    await tester.pumpAndSettle();

    // Assert — nothing to assert but that it survived the tap and still reads.
    expect(find.text('بانتظار رسالة الجاهزية'), findsOneWidget);
  });
}
