import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/wallet/presentation/widgets/adjust_wallet_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «تعديل الرصيد» ورقةً من الأسفل لا حواراً — بطلب صاحب العمل (٢٠٢٦-١٠-١٧)، على شكل ورقة
/// «شحن المحفظة» أختِها.
///
/// Arrange - Act - Assert throughout.
void main() {
  late List<({String amount, bool credit, String reason})> sent;

  Future<void> open(WidgetTester tester, {String balance = '60.00'}) async {
    sent = [];

    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
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
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAdjustWalletSheet(
                  context: context,
                  balance: balance,
                  onSubmit: ({required amount, required credit, required reason}) async {
                    sent.add((amount: amount, credit: credit, reason: reason));

                    return null;
                  },
                ),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('it is a sheet from the bottom, not a dialog', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('تعديل الرصيد'), findsOneWidget);
  });

  testWidgets('the balance after the change is shown as it is typed', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.enterText(field('المبلغ'), '15');
    await tester.pump();

    // Assert
    expect(find.text('الرصيد بعد التعديل'), findsOneWidget);
    expect(find.text('75 د.ل'), findsOneWidget);
  });

  testWidgets('a decrease turns the same amount the other way', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.text('نقص'));
    await tester.enterText(field('المبلغ'), '15');
    await tester.pump();

    // Assert
    expect(find.text('45 د.ل'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'خصم من الرصيد'), findsOneWidget);
  });

  testWidgets('a decrease past the balance is refused before it is sent', (tester) async {
    // Arrange
    await open(tester);
    await tester.tap(find.text('نقص'));
    await tester.enterText(field('المبلغ'), '100');
    await tester.enterText(field('السبب'), 'تصحيح خطأ');
    await tester.pump();

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'خصم من الرصيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(sent, isEmpty);
    expect(find.text('في المحفظة 60 د.ل فقط'), findsOneWidget);
  });

  testWidgets('Arabic digits go out as Western ones', (tester) async {
    // Arrange
    await open(tester);
    await tester.enterText(field('المبلغ'), '١٥');
    await tester.enterText(field('السبب'), 'تعويض عن عيب');
    await tester.pump();

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'إضافة للرصيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(sent, [(amount: '15', credit: true, reason: 'تعويض عن عيب')]);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a reason is required', (tester) async {
    // Arrange
    await open(tester);
    await tester.enterText(field('المبلغ'), '15');
    await tester.pump();

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'إضافة للرصيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(sent, isEmpty);
    expect(find.text('السبب مطلوب'), findsOneWidget);
  });
}
