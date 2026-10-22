import 'package:dayaa/core/chat/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// الفقاعة: **الكلامُ بخطٍّ يُقرأ** — ١٧ على هاتفٍ بعرض ٤٣٠ لا ١٦ الثيم، والوقتُ تحته ١٢ لا ١١،
/// طلبُ المالك ٢٠٢٦-١٠-٢٣ («حسّن من حجم الخط نفسه وطريقة العرض ليكون واضحاً»).
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    ),
  );

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  testWidgets('the words are drawn at 17 and the time under them at 12', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        MessageBubble(
          fromDesk: true,
          startsRun: true,
          endsRun: true,
          text: 'Hello',
          sentAt: DateTime(2026, 10, 23, 12, 24),
        ),
      ),
    );

    // Act
    final words = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().startsWith('Hello'),
      ),
    );
    final time = tester.widget<Text>(find.textContaining('12:24').first);

    // Assert
    expect(words.text.style?.fontSize, 17);
    expect(time.style?.fontSize, 12);
  });
}
