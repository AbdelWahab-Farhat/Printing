import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/review_version_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مراجعة النسخة» — two verdicts, two buttons.
///
/// **It was a segmented control and one button**, which made a two-tap job of a choice between
/// two things and left the confirm button renaming itself under the reader's finger. The
/// warning that approving cannot be undone sat on the sheet as grey prose, where it was read
/// once and then never again; it is in the confirmation now, where it is read every time.
///
/// Arrange - Act - Assert throughout.
void main() {
  const version = DesignTicketFile(
    id: 3,
    designTicketId: 1,
    kind: DesignTicketFileKind.submission,
    kindLabel: 'نسخة',
    label: 'النسخة 1',
    fileKind: DesignKind.image,
    fileKindLabel: 'صورة',
  );

  late ReviewChoice? answer;

  /// Opens the sheet and keeps whatever it answered with.
  Widget host() => ScreenUtilInit(
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
                  answer = await showReviewVersionSheet(context: context, version: version);
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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('both verdicts are buttons, and neither is a segment', (tester) async {
    // Arrange - Act
    await open(tester);

    // Assert
    expect(find.text('اعتماد التصميم'), findsOneWidget);
    expect(find.text('طلب تعديل'), findsOneWidget);
    expect(find.byType(SegmentedButton<DesignSubmissionStatus>), findsNothing);
  });

  testWidgets('approving asks first, and backing out answers nothing', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.text('اعتماد التصميم'));
    await tester.pumpAndSettle();
    expect(find.text('اعتماد التصميم؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert — the sheet is still open and nothing was decided.
    expect(answer, isNull);
    expect(find.text('طلب تعديل'), findsOneWidget);
  });

  testWidgets('confirming an approval answers with it', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.text('اعتماد التصميم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعتماد'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer?.verdict, DesignSubmissionStatus.approved);
  });

  testWidgets('a change request with no note is refused before it is asked', (tester) async {
    // Arrange — the server refuses an empty one too; catching it here is what puts the
    // complaint under the box instead of in a toast after the sheet has closed.
    await open(tester);

    // Act
    await tester.tap(find.text('طلب تعديل'));
    await tester.pumpAndSettle();

    // Assert — no dialog, no answer, and the reason is on screen.
    expect(find.text('طلب تعديل؟'), findsNothing);
    expect(answer, isNull);
    expect(find.text('اكتب ما المطلوب تعديله'), findsOneWidget);
  });

  testWidgets('a change request with a note asks, then answers with both', (tester) async {
    // Arrange
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'كبّر الشعار');

    // Act
    await tester.tap(find.text('طلب تعديل'));
    await tester.pumpAndSettle();
    expect(find.text('طلب تعديل؟'), findsOneWidget);
    await tester.tap(find.text('إرسال'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer?.verdict, DesignSubmissionStatus.changesRequested);
    expect(answer?.note, 'كبّر الشعار');
  });
}
