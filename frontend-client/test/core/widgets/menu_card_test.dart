import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// بطاقة الصفوف في «حسابي» و«الإعدادات»: أيقونةٌ في دائرة، واسمٌ، وسهمٌ إلى حيث يذهب الصف.
///
/// **ثلاثة أنواعٍ من الصفوف في البطاقة نفسها، وكلٌّ منها يُقرأ مختلفاً قبل أن يُلمس:** صفٌّ يذهب
/// إلى مكان (له سهم)، وصفٌّ لم يُفتح بعد (باهت، بلا سهم، ولا يستجيب)، وصفٌّ يُنهي شيئاً (بلون
/// الخطأ وبلا سهم، لأنه ليس مكاناً تذهب إليه).
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(List<MenuRow> rows) => ScreenUtilInit(
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
        body: ListView(children: [MenuCard(rows: rows)]),
      ),
    ),
  );

  /// ما يرسمه الصف نفسه، لا ما ترسمه الشاشة حوله.
  Finder inRow(Finder finder) => find.descendant(of: find.byType(MenuRow), matching: finder);

  testWidgets('tapping a row runs what it is for', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(
      host([MenuRow(icon: AppIcons.settings, label: 'الإعدادات', onTap: () => taps++)]),
    );

    // Act
    await tester.tap(find.text('الإعدادات'));
    await tester.pump();

    // Assert
    expect(taps, 1);
  });

  testWidgets('a row that goes somewhere carries the chevron', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      host([MenuRow(icon: AppIcons.settings, label: 'الإعدادات', onTap: () {})]),
    );

    // Assert
    expect(find.byIcon(AppIcons.forward), findsOneWidget);
  });

  testWidgets('what a row is set to is drawn before its chevron', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      host([
        MenuRow(
          icon: AppIcons.appearance,
          label: 'مظهر التطبيق',
          value: 'داكن',
          onTap: () {},
        ),
      ]),
    );

    // Assert — «قبل» في العربية يعني إلى اليمين: القيمة أبعد عن الحافة اليسرى من السهم.
    final value = tester.getRect(find.text('داكن'));
    final chevron = tester.getRect(find.byIcon(AppIcons.forward));

    expect(value.center.dx, greaterThan(chevron.center.dx));
  });

  testWidgets('a row with nothing behind it yet is dimmed, has no chevron, and ignores the tap', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host([
        const MenuRow(icon: Icons.circle, label: 'سياسة الخصوصية', badge: 'قريباً', onTap: null),
      ]),
    );

    // Act — لا شيء يُنتظر أن يحدث، والمطلوب أن يبقى كذلك: لا خطأ ولا حبر.
    await tester.tap(find.text('سياسة الخصوصية'));
    await tester.pump();

    // Assert
    final dim = tester.widget<Opacity>(inRow(find.byType(Opacity)));

    expect(dim.opacity, lessThan(1));
    expect(find.text('قريباً'), findsOneWidget);
    expect(find.byIcon(AppIcons.forward), findsNothing);
    expect(inRow(find.byType(InkWell)), findsNothing);
  });

  testWidgets('signing out wears the error colour and carries no chevron', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      host([
        MenuRow(
          icon: AppIcons.logout,
          label: 'تسجيل الخروج',
          isDestructive: true,
          onTap: () {},
        ),
      ]),
    );

    // Assert — ليس مكاناً تذهب إليه فلا سهم له، ولونه يقول إنه يُنهي شيئاً قبل أن يُقرأ.
    final label = tester.widget<Text>(find.text('تسجيل الخروج'));
    final scheme = Theme.of(tester.element(find.text('تسجيل الخروج'))).colorScheme;

    expect(label.style?.color, scheme.error);
    expect(find.byIcon(AppIcons.forward), findsNothing);
  });

  testWidgets('a busy row says it is working and does not take a second tap', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(
      host([
        MenuRow(
          icon: AppIcons.logout,
          label: 'تسجيل الخروج',
          isDestructive: true,
          isBusy: true,
          onTap: () => taps++,
        ),
      ]),
    );

    // Act
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pump();

    // Assert — مشغولٌ لا معطَّل: الصف لا يبهت، والدائرة تدور مكان الأيقونة.
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(AppIcons.logout), findsNothing);
    expect(inRow(find.byType(Opacity)), findsNothing);
  });
}
