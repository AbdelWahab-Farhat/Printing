import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which corner the bell actually lands in.
///
/// **The same trap as the floating basket, in a different widget.** This app is `Locale('ar')`
/// and nothing else, so an `AppBar` lays its `actions` out from the *trailing* edge — the left —
/// inward. The entry nearest the screen's left edge is therefore the **last** one in the list,
/// which is the opposite of what the code reads like to anybody who thinks in English. A tidy-up
/// that moved the bell to the front of `actions` would slide it inward, past the cart, without a
/// single test going red.
///
/// **Measured rather than eyeballed**, like `cart_fab_layout_test.dart` and
/// `badged_tile_layout_test.dart`: a layout failure throws nothing and shows nothing in red.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host({List<Widget> actions = const [NotificationsButton()]}) => ScreenUtilInit(
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
        appBar: AppBar(title: const Text('شاشة'), actions: actions),
        body: const SizedBox.expand(),
      ),
    ),
  );

  testWidgets('the bell sits in the left half of the bar', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final bell = tester.getRect(find.byType(NotificationsButton));
    final bar = tester.getRect(find.byType(AppBar));

    expect(bell.center.dx, lessThan(bar.center.dx));
  });

  testWidgets('last in actions puts it nearest the left edge, past anything else', (
    tester,
  ) async {
    // Arrange — a bar that already has an action, as «تصاميمي» and the product screen do.
    const other = Key('other-action');

    // Act
    await tester.pumpWidget(
      host(
        actions: const [
          IconButton(key: other, onPressed: null, icon: Icon(Icons.circle)),
          NotificationsButton(),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Assert — the bell is the outermost, which in Arabic means the smallest x.
    final bell = tester.getRect(find.byType(NotificationsButton));
    final neighbour = tester.getRect(find.byKey(other));

    expect(
      bell.center.dx,
      lessThan(neighbour.center.dx),
      reason: 'the bell must be the outermost action; first in the list would nest it inward',
    );
  });

  testWidgets('it is drawn even with nothing to report', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — unlike the basket, which hides when empty: the bell is the way *in* to a screen
    // somebody may want to check precisely when it is empty.
    expect(find.byType(NotificationsButton), findsOneWidget);
  });

  testWidgets('the empty screen says so, and promises nothing', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert — no shimmer, no placeholder rows, no «قريباً»: an empty list reads as empty.
    expect(find.text('لا توجد إشعارات'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
