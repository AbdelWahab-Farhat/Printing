import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet that asks where a file is coming from.
///
/// Testable at all because it picks nothing: it answers an [AttachmentSource] and closes, and
/// the caller takes that to the picker. Both picker packages talk over a platform channel that
/// does not exist here.
///
/// Arrange - Act - Assert throughout.
void main() {
  late AttachmentSource? chosen;
  late bool wasOpened;

  setUp(() {
    chosen = null;
    wasOpened = false;
  });

  Widget host({List<AttachmentSource> sources = AttachmentSource.values}) => ScreenUtilInit(
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
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                wasOpened = true;
                chosen = await showAttachmentSheet(context: context, sources: sources);
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('offers the three places a design can come from', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert — «صور» is the one that matters most and is the easiest to leave out: on iOS the
    // document browser cannot see the photo library at all, which is where anything sent over
    // WhatsApp lands.
    expect(find.text('مستندات'), findsOneWidget);
    expect(find.text('صور'), findsOneWidget);
    expect(find.text('الكاميرا'), findsOneWidget);
  });

  testWidgets('tapping one answers with it and closes', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('صور'));
    await tester.pumpAndSettle();

    // Assert
    expect(chosen, AttachmentSource.photos);
    expect(find.text('مستندات'), findsNothing, reason: 'the sheet should have closed');
  });

  testWidgets('backing out is an answer of null, not a failure', (tester) async {
    // Arrange — a person changing their mind is the expected ending of this call, and nothing
    // should be reported to them about it.
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Act — the scrim.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(wasOpened, isTrue);
    expect(chosen, isNull);
  });

  testWidgets('a caller that offers fewer sources gets fewer', (tester) async {
    // Arrange — a screen with no use for the camera should not show one.
    await tester.pumpWidget(
      host(sources: const [AttachmentSource.documents, AttachmentSource.photos]),
    );

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الكاميرا'), findsNothing);
    expect(find.text('مستندات'), findsOneWidget);
  });
}
