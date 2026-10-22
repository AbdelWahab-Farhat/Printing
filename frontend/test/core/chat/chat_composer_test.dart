import 'package:dayaa/core/chat/chat_composer.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// صندوق الكتابة: **زرُّ الإرسال في أوّل السطر** — يمينَ الحقل بالعربية ويسارَه بالإنجليزية، طلبُ
/// المالك ٢٠٢٦-١٠-٢٣ — والميكروفونُ في مكانه نفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Locale locale, {bool voice = false, String text = ''}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChatComposer(
            controller: TextEditingController(text: text),
            onSend: () {},
            onAttach: () {},
            onRecorded: voice ? (_) async {} : null,
          ),
        ),
      ),
    ),
  );

  double centreOf(WidgetTester tester, Finder finder) => tester.getCenter(finder).dx;

  testWidgets('in Arabic the send key sits to the right of the field', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const Locale('ar'), text: 'مرحبا'));

    // Act
    final send = centreOf(tester, find.byIcon(AppIcons.send));
    final field = centreOf(tester, find.byType(TextField));

    // Assert
    expect(send, greaterThan(field));
  });

  testWidgets('in English the send key sits to the left of the field', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const Locale('en'), text: 'hello'));

    // Act
    final send = centreOf(tester, find.byIcon(AppIcons.send));
    final field = centreOf(tester, find.byType(TextField));

    // Assert
    expect(send, lessThan(field));
  });

  testWidgets('the microphone takes the same place as the send key', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const Locale('ar'), voice: true));

    // Act
    final mic = centreOf(tester, find.byIcon(AppIcons.mic));
    final field = centreOf(tester, find.byType(TextField));

    // Assert
    expect(mic, greaterThan(field));
  });
}
