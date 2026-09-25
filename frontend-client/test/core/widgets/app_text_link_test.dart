import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// الرابط النصّي المشترك: «إنشاء حساب جديد» و«نسيتها؟» وكل كلمةٍ تُنقر بدل زرٍّ كامل.
///
/// Arrange - Act - Assert throughout.
void main() {
  const label = 'إنشاء حساب جديد';

  /// الإطار الذي يُقلع فيه التطبيق: ScreenUtil على مقاس التصميم المرجعي، عربيّ، ومن اليمين.
  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        theme: ThemeData(colorScheme: MaterialTheme.lightScheme),
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
  }

  testWidgets('a tap runs it', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(host(AppTextLink(label: label, onPressed: () => taps++)));

    // Act
    await tester.tap(find.text(label));

    // Assert
    expect(taps, 1);
  });

  testWidgets('it wears the brand colour, heavier than the words around it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(AppTextLink(label: label, onPressed: () {})));

    // Act
    final style = tester.widget<Text>(find.text(label)).style!;

    // Assert
    expect(style.color, MaterialTheme.lightScheme.primary);
    expect(style.fontWeight, FontWeight.w700);
  });

  testWidgets('a screen reader hears a link it can open', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(AppTextLink(label: label, onPressed: () {})));

    // Act
    final node = tester.getSemantics(find.bySemanticsLabel(label));

    // Assert
    expect(node, isSemantics(label: label, isLink: true, hasTapAction: true));
    semantics.dispose();
  });
}
