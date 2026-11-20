import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/design_tickets/models/design_version_rules.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_images_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each pick with the next list the test queued, as a person picking again would.
///
/// A fake rather than the real picker: both packages behind it answer through a platform
/// channel that does not exist under `flutter_test`.
class _QueuedPicker implements AttachmentPicker {
  final List<List<PickedFile>> answers = [];

  @override
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = AttachmentPicker.defaultExtensions,
  }) async => answers.isEmpty ? const [] : answers.removeAt(0);
}

/// «صور التصميم» — a version gathered one pick at a time (owner, 2026-11-20).
///
/// Arrange - Act - Assert throughout.
void main() {
  late _QueuedPicker picker;

  /// What the sheet handed back, and whether it has closed at all.
  List<PickedFile>? result;
  var closed = false;

  PickedFile image(String name, {int size = 1024}) =>
      PickedFile(path: '/tmp/$name', name: name, sizeBytes: size);

  setUp(() {
    picker = _QueuedPicker();
    result = null;
    closed = false;
    sl.registerSingleton<AttachmentPicker>(picker);
  });

  tearDown(() => sl.reset());

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
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDesignVersionImagesSheet(context: context);
              closed = true;
            },
            child: const Text('رفع التصميم'),
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('رفع التصميم'));
    await tester.pumpAndSettle();
  }

  /// «إضافة صورة», answered from the gallery with whatever is queued next.
  Future<void> add(WidgetTester tester, List<PickedFile> picked) async {
    picker.answers.add(picked);
    await tester.tap(find.bySemanticsLabel('إضافة صورة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صور'));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
  }

  testWidgets('images picked one at a time all go in, in the order they were added', (
    tester,
  ) async {
    // Arrange
    await openTheSheet(tester);

    // Act — three separate picks, as three camera shots would be.
    await add(tester, [image('front.jpg')]);
    await add(tester, [image('back.jpg')]);
    await add(tester, [image('logo.png')]);
    await next(tester);

    // Assert
    expect(closed, isTrue);
    expect([for (final file in result!) file.name], ['front.jpg', 'back.jpg', 'logo.png']);
  });

  testWidgets('a pick of several still adds them all, after what is already there', (
    tester,
  ) async {
    // Arrange
    await openTheSheet(tester);
    await add(tester, [image('front.jpg')]);

    // Act
    await add(tester, [image('back.jpg'), image('side.webp')]);
    await next(tester);

    // Assert
    expect([for (final file in result!) file.name], ['front.jpg', 'back.jpg', 'side.webp']);
  });

  testWidgets('«التالي» does nothing below two images', (tester) async {
    // Arrange
    await openTheSheet(tester);
    await add(tester, [image('front.jpg')]);

    // Act
    await next(tester);

    // Assert — still open, nothing handed back.
    expect(closed, isFalse);
    expect(find.text('صور التصميم (1 من 6)'), findsOneWidget);
  });

  testWidgets('removing one takes it off, and below two «التالي» stops again', (tester) async {
    // Arrange
    await openTheSheet(tester);
    await add(tester, [image('front.jpg'), image('back.jpg')]);

    // Act
    await tester.tap(find.bySemanticsLabel('إزالة المرفق').first);
    await tester.pumpAndSettle();
    await next(tester);

    // Assert
    expect(find.text('صور التصميم (1 من 6)'), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('six is the most: the add square goes and a seventh is refused', (tester) async {
    // Arrange
    await openTheSheet(tester);
    await add(tester, [for (var i = 1; i <= 5; i++) image('$i.jpg')]);

    // Act — two more when only one fits.
    await add(tester, [image('6.jpg'), image('7.jpg')]);

    // Assert
    expect(find.text('صور التصميم (6 من 6)'), findsOneWidget);
    expect(find.text(DesignVersionRules.tooMany), findsOneWidget);
    expect(find.bySemanticsLabel('إضافة صورة'), findsNothing);
  });

  testWidgets('the same image twice goes in once, and says so', (tester) async {
    // Arrange — the gallery hands back a fresh copy, so the path differs and the name and
    // size do not.
    await openTheSheet(tester);
    await add(tester, [image('front.jpg')]);

    // Act
    await add(tester, [
      const PickedFile(path: '/tmp/copy/front.jpg', name: 'front.jpg', sizeBytes: 1024),
    ]);

    // Assert
    expect(find.text('صور التصميم (1 من 6)'), findsOneWidget);
    expect(find.text(DesignVersionRules.duplicate), findsOneWidget);
  });

  testWidgets('a PDF is not one of the images', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await add(tester, [image('front.jpg'), image('print.pdf')]);

    // Assert
    expect(find.text('صور التصميم (1 من 6)'), findsOneWidget);
    expect(find.text(DesignVersionRules.notAnImage), findsOneWidget);
  });

  testWidgets('dismissing the sheet hands back nothing', (tester) async {
    // Arrange
    await openTheSheet(tester);
    await add(tester, [image('front.jpg'), image('back.jpg')]);

    // Act — the barrier above the sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(closed, isTrue);
    expect(result, isNull);
  });
}
