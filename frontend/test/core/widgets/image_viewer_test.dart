import 'dart:async';

import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one full-screen picture viewer.
///
/// **A URL list, not a model**, which is what lets a ticket's version, a product's photo and a
/// customer's design share it instead of each growing its own dialog.
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
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );

  testWidgets('one picture is shown without a counter over it', (tester) async {
    // Arrange - Act
    await tester.pumpWidget(host(const ImageViewerPage(urls: ['https://x/1.png'])));
    await tester.pump();

    // Assert — «١ / ١» says nothing and covers part of the picture.
    expect(find.textContaining('/'), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('several are counted, and it opens on the one that was tapped', (tester) async {
    // Arrange - Act
    await tester.pumpWidget(
      host(
        const ImageViewerPage(
          urls: ['https://x/1.png', 'https://x/2.png', 'https://x/3.png'],
          initialIndex: 1,
        ),
      ),
    );
    await tester.pump();

    // Assert
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('an index past the end is pulled back rather than thrown', (tester) async {
    // Arrange — a caller whose list and index came from two different reads.
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );

    // Act
    unawaited(
      openImageViewer(key.currentContext!, urls: ['https://x/1.png'], initialIndex: 9),
    );
    // Pumped rather than settled: the placeholder is a spinner, which never stops animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.byType(ImageViewerPage), findsOneWidget);
  });

  testWidgets('an empty list opens nothing at all', (tester) async {
    // Arrange
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );

    // Act
    await openImageViewer(key.currentContext!, urls: const []);
    await tester.pump();

    // Assert — a black screen with nothing on it is worse than no response to the tap.
    expect(find.byType(ImageViewerPage), findsNothing);
  });

  testWidgets('a drag down closes it', (tester) async {
    // Arrange
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );
    unawaited(openImageViewer(key.currentContext!, urls: ['https://x/1.png']));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ImageViewerPage), findsOneWidget);

    // Act — the gesture every photo viewer on the phone has.
    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(find.byType(ImageViewerPage), findsNothing);
  });
}
