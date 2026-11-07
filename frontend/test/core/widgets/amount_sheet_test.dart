import 'package:dayaa/core/widgets/amount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ورقة مبلغٍ واحد — أجر التذكرة، والسعر المقترح، والقبول.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  late AmountChoice? answer;

  Widget host({String? initial, String? description}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  answer = await showAmountSheet(
                    context: context,
                    title: 'أجر التصميم',
                    label: 'المبلغ',
                    confirmLabel: 'حفظ',
                    initial: initial,
                    description: description,
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  setUp(() => answer = null);

  Future<void> open(WidgetTester tester, {String? initial, String? description}) async {
    await tester.pumpWidget(host(initial: initial, description: description));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the suggested amount is already written, without its zeros', (tester) async {
    // Arrange - Act
    await open(tester, initial: '75.00');

    // Assert
    expect(find.widgetWithText(TextFormField, '75'), findsOneWidget);
  });

  testWidgets('the amount comes back in western digits', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.enterText(find.byType(TextFormField), '٥٠');
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer?.amount, '50');
  });

  testWidgets('an empty box answers with no amount, which is a decision', (tester) async {
    // Arrange
    await open(tester, initial: '75.00');

    // Act
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer, isNotNull);
    expect(answer?.amount, isNull);
  });

  testWidgets('dismissing the sheet is no answer at all', (tester) async {
    // Arrange
    await open(tester, initial: '75.00');

    // Act
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(answer, isNull);
  });

  testWidgets('a description is drawn when there is one', (tester) async {
    // Arrange - Act
    await open(tester, description: 'ستصبح أنت المصمم المسؤول');

    // Assert
    expect(find.text('ستصبح أنت المصمم المسؤول'), findsOneWidget);
  });
}
