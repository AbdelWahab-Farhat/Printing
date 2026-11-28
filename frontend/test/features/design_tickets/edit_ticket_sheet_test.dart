import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/edit_ticket_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «تعديل الطلب»: the sheet in cards, and the description on a page of its own.
///
/// Arrange - Act - Assert throughout.
void main() {
  final ticket = DesignTicket.fromJson(const {
    'id': 1,
    'code': 'D92',
    'title': 'تصميم طلبية 1600',
    'description': 'توحيد باللون الذهبي',
    'status': 'in_progress',
    'status_label': 'قيد التصميم',
    'customer_id': 1,
    'customer_name': 'متجر',
    'designer_pay': '10.00',
    'suggested_pay': '10.00',
    'can_set_pay': true,
  });

  /// Opens the sheet from a button and keeps what it pops with.
  Future<TicketEdit? Function()> open(WidgetTester tester) async {
    TicketEdit? result;

    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showEditTicketSheet(context: context, ticket: ticket),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    return () => result;
  }

  testWidgets('shows the code and saves what is in the boxes', (tester) async {
    // Arrange
    final result = await open(tester);
    expect(find.text('D92'), findsOneWidget);

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'تصميم طلبية 1600'), 'عنوان جديد');
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert
    expect(result()?.title, 'عنوان جديد');
    expect(result()?.description, 'توحيد باللون الذهبي');
  });

  testWidgets('the full-screen editor is a plain box whose Return starts a new line', (
    tester,
  ) async {
    // Arrange
    final result = await open(tester);
    await tester.tap(find.text('ملء الشاشة'));
    await tester.pumpAndSettle();

    // Act — the system keyboard types a line break and reports Return, as iOS does.
    await tester.enterText(find.byType(TextField), '${_text(tester)}\nالشعار في المنتصف');
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();

    // Assert — no toolbar of its own, the keyboard is set for several lines, and Return kept
    // the box focused rather than leaving it.
    expect(find.text('نقطة جديدة'), findsNothing);
    expect(find.text('لصق'), findsNothing);
    expect(find.text('تحديد الكل'), findsNothing);
    final keyboard = tester.testTextInput.setClientArgs!;
    expect(keyboard['inputAction'], 'TextInputAction.newline');
    expect((keyboard['inputType'] as Map)['name'], 'TextInputType.multiline');
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);

    // Act — back to the sheet, and save.
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert — the line break survives the round trip.
    expect(result()?.description, 'توحيد باللون الذهبي\nالشعار في المنتصف');
  });

  testWidgets('the sheet no longer carries the Return-key hint', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(find.text('Return ينزل سطراً جديداً'), findsNothing);
    expect(find.text('ملء الشاشة'), findsOneWidget);
  });
}

String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;
