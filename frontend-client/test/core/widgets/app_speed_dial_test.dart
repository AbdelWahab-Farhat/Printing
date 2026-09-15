import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/app_speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's floating button, and the three shapes it takes.
///
/// **The staff app's copy of this file tests a fourth thing — the permission filter — and this
/// one does not, because this widget has none.** A customer's account carries no role matrix.
/// The day the API grants this app abilities per account, those cases come back with the filter.
///
/// Arrange - Act - Assert throughout.
void main() {
  AppAction action(String label, {VoidCallback? onTap}) => AppAction(
    label: label,
    icon: AppIcons.edit,
    onTap: (_) => onTap?.call(),
  );

  /// A real phone, not the 800×600 the test binding defaults to.
  ///
  /// The clipping this file guards against only happens when the screen is narrow enough for a
  /// label to reach the far edge — at 800 wide every assertion below passes against nothing.
  void useAPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// The frame the app actually boots into.
  ///
  /// The locale goes on `MaterialApp`, not on a `Directionality` around the `Scaffold`, and the
  /// difference is not cosmetic: the dial draws its children into the app's **overlay**, which
  /// sits above the Scaffold. Wrapping only the Scaffold leaves that overlay left-to-right and
  /// the test measures a layout the app never produces.
  Widget host(List<AppAction> actions) => ScreenUtilInit(
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
        floatingActionButtonLocation: AppSpeedDial.location,
        floatingActionButton: AppSpeedDial(actions: actions),
      ),
    ),
  );

  testWidgets('an empty list renders nothing at all', (tester) async {
    // Arrange — a screen whose actions all turned out to be inapplicable.
    useAPhone(tester);

    // Act
    await tester.pumpWidget(host(const []));

    // Assert — an empty dial is furniture.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('one action is a plain button, not a dial to open', (tester) async {
    // Arrange
    useAPhone(tester);

    // Act
    await tester.pumpWidget(host([action('التصاميم')]));

    // Assert — the label is on the button itself, with nothing to expand.
    expect(find.text('التصاميم'), findsOneWidget);
  });

  testWidgets('several actions open as a dial, with every label on screen', (
    tester,
  ) async {
    // Arrange — the bug this widget exists to prevent: the package lays its rows out from the
    // start edge, which in Arabic is the far side from the button, and the labels walk off.
    useAPhone(tester);
    await tester.pumpWidget(
      host([
        action('تعديل الطلبية'),
        action('إلغاء الطلبية'),
        action('التصاميم'),
      ]),
    );

    // Act
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    // Assert
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    for (final label in const ['تعديل الطلبية', 'إلغاء الطلبية', 'التصاميم']) {
      final rect = tester.getRect(find.text(label));
      expect(
        rect.left,
        greaterThanOrEqualTo(0),
        reason: '«$label» runs off the left edge',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(width),
        reason: '«$label» runs off the right edge',
      );
    }
  });

  testWidgets('a name is readable, not squeezed against its icon', (tester) async {
    // Arrange — the defect this replaced: the package's own label slot renders inside the
    // Scaffold's 56-wide floating-button slot, so «تعديل الطلبية» came out 26 pixels wide and
    // painted over its own icon.
    useAPhone(tester);
    await tester.pumpWidget(host([action('تعديل الطلبية'), action('التصاميم')]));

    // Act
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();

    // Assert
    for (final label in const ['تعديل الطلبية', 'التصاميم']) {
      final text = tester.getRect(find.text(label));
      final icon = tester.getRect(
        find
            .descendant(
              of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
              matching: find.byType(Icon),
            )
            .first,
      );

      // Which side the icon sits on is the row's business — Arabic puts it on the right — so
      // the gap is measured whichever way round they came out.
      final gap = text.left > icon.left ? text.left - icon.right : icon.left - text.right;

      // Wide enough to be the whole name rather than an ellipsis, and clear of the icon.
      expect(text.width, greaterThan(40), reason: '«$label» is squeezed');
      expect(gap, greaterThan(4), reason: '«$label» touches its icon');
    }
  });

  testWidgets('tapping an action runs it', (tester) async {
    // Arrange
    useAPhone(tester);
    var taps = 0;

    await tester.pumpWidget(host([action('التصاميم', onTap: () => taps++)]));

    // Act
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(taps, 1);
  });
}
