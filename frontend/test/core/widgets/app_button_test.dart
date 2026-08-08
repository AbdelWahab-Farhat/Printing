import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/widgets/app_button.dart';

/// The shared button's behaviour — the part that is not decoration.
///
/// **Never `pumpAndSettle` while the button is busy.** The lap controller repeats forever, so
/// settling waits for a frame that never comes and the test times out. Every wait below is an
/// explicit `pump(duration)` longer than the animation being awaited. Reduced motion is the one
/// exception: nothing runs there at all.
///
/// Arrange - Act - Assert throughout.
void _noop() {}

void main() {
  // Fixed rather than taken from ScreenUtil: the geometry assertions below compare against real
  // numbers, and a value that changes with the test surface would make them meaningless.
  const width = 300.0;
  const height = 56.0;
  const label = 'تسجيل الدخول';

  /// The same frame the app boots into: ScreenUtil at the reference design size, Arabic, RTL.
  ///
  /// [reducedMotion] is the accessibility setting "remove animations", which the OS reports
  /// through `MediaQuery.disableAnimations`.
  ///
  /// [imposeWidth] off is the other half the button meets in real screens — a `Wrap`, or a
  /// centred `Column` — where nothing hands it a width and it has to measure itself.
  Widget host(Widget button, {bool reducedMotion = false, bool imposeWidth = true}) {
    return ScreenUtilInit(
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
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Center(
                  child: imposeWidth ? SizedBox(width: width, child: button) : button,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// How far the legend has sunk. `storage[13]` is the y translation of the matrix.
  double sinkOf(WidgetTester tester) =>
      tester.widget<Transform>(find.byKey(AppButton.contentKey)).transform.storage[13];

  Material surfaceOf(WidgetTester tester) => tester.widget<Material>(
    find.descendant(of: find.byKey(AppButton.surfaceKey), matching: find.byType(Material)),
  );

  AppButtonThreadPainter threadOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(AppButton.threadKey)).painter!
          as AppButtonThreadPainter;

  /// Holds the button down and gives the press animation room to have happened.
  ///
  /// Two pumps, not one, and the reason is easy to trip over: a tap-down is only reported once
  /// `kPressTimeout` has passed, so the first pump merely *starts* the animation — the frame it
  /// draws is still the resting one. Assert after a single pump and every press test passes for
  /// the wrong reason, including the ones below that expect nothing to move.
  Future<TestGesture> holdDown(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byType(AppButton)));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 80));

    return gesture;
  }

  group('the action', () {
    testWidgets('a tap runs it', (tester) async {
      // Arrange
      var taps = 0;
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () => taps++)),
      );

      // Act
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Assert
      expect(taps, 1);
    });

    testWidgets('a busy button ignores taps', (tester) async {
      // Arrange — the caller keeps handing us `onPressed`; the guard is ours, not theirs.
      var taps = 0;
      await tester.pumpWidget(
        host(
          AppButton(
            label: label,
            height: height,
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      // Assert
      expect(taps, 0);
    });

    testWidgets('a disabled button neither reacts nor moves', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(const AppButton(label: label, height: height, onPressed: null)),
      );

      // Act
      final gesture = await holdDown(tester);

      // Assert — no press animation on something that cannot be pressed.
      expect(sinkOf(tester), 0);

      await gesture.up();
      await tester.pump();
    });
  });

  group('the size never changes', () {
    testWidgets('going busy moves neither the button nor its surface', (tester) async {
      // Arrange — this is the assertion that encodes the whole design rule, so it reads the
      // real painted rectangles rather than a width alone.
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );
      final box = tester.getRect(find.byKey(AppButton.surfaceKey));
      final surface = tester.getRect(
        find.descendant(
          of: find.byKey(AppButton.surfaceKey),
          matching: find.byType(Material),
        ),
      );

      // Act
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, isLoading: true, onPressed: () {})),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(tester.getRect(find.byKey(AppButton.surfaceKey)), box);
      expect(
        tester.getRect(
          find.descendant(
            of: find.byKey(AppButton.surfaceKey),
            matching: find.byType(Material),
          ),
        ),
        surface,
      );
      expect(box.width, width);
      expect(box.height, height);
    });

    testWidgets('holding it down moves neither', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );
      final box = tester.getRect(find.byKey(AppButton.surfaceKey));

      // Act
      final gesture = await holdDown(tester);

      // Assert — the legend moved; the button did not.
      expect(sinkOf(tester), isNot(0));
      expect(tester.getRect(find.byKey(AppButton.surfaceKey)), box);

      await gesture.up();
      await tester.pump();
    });
  });

  group('busy', () {
    testWidgets('the label stays put and a thread appears', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );
      final labelAt = tester.getCenter(find.text(label));
      expect(find.byKey(AppButton.threadKey), findsNothing);

      // Act
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, isLoading: true, onPressed: () {})),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Assert — nothing was swapped out for a spinner.
      expect(find.text(label), findsOneWidget);
      expect(tester.getCenter(find.text(label)), labelAt);
      expect(find.byKey(AppButton.threadKey), findsOneWidget);
    });

    testWidgets('the thread leaves again when the work ends', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, isLoading: true, onPressed: () {})),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(AppButton.threadKey), findsOneWidget);

      // Act
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert — an idle button pays for neither the painter nor its layer.
      expect(find.byKey(AppButton.threadKey), findsNothing);
    });

    testWidgets('the thread runs with the reading direction', (tester) async {
      // Arrange — the host is RTL, which is the only direction this app is ever in.
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, isLoading: true, onPressed: () {})),
      );

      // Act
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(threadOf(tester).clockwise, isFalse);
    });
  });

  group('press', () {
    testWidgets('holding sinks the legend, releasing springs it back', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );

      // Act
      final gesture = await holdDown(tester);

      // Assert
      expect(sinkOf(tester), greaterThan(0));

      // Act — release. The bare pump is not padding: a Ticker counts from its first frame, not
      // from the moment it was started, so a lone `pump(700)` draws the spring's opening frame
      // and reports the button as still held.
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Assert — the spring overshoots on the way out, but it lands exactly at rest.
      expect(sinkOf(tester), moreOrLessEquals(0, epsilon: 0.001));
    });
  });

  group('reduced motion', () {
    testWidgets('nothing moves when held down', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          AppButton(label: label, height: height, onPressed: () {}),
          reducedMotion: true,
        ),
      );

      // Act — the identical sequence to the press test above, so the only difference between
      // them is the setting.
      final gesture = await holdDown(tester);

      // Assert — not "animated quickly": not animated.
      expect(sinkOf(tester), 0);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('busy arrives in one frame, and holds still', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          AppButton(label: label, height: height, onPressed: () {}),
          reducedMotion: true,
        ),
      );

      // Act
      await tester.pumpWidget(
        host(
          AppButton(label: label, height: height, isLoading: true, onPressed: () {}),
          reducedMotion: true,
        ),
      );
      await tester.pump();

      // Assert — present immediately, and with no lap the painter draws a complete, still rim
      // instead of an arc frozen somewhere along the edge.
      expect(find.byKey(AppButton.threadKey), findsOneWidget);
      expect(threadOf(tester).lap, isNull);

      // And with nothing running, the tree is allowed to settle.
      await tester.pumpAndSettle();
    });
  });

  group('appearance', () {
    testWidgets('an icon sits beside the label', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          AppButton(
            label: 'حفظ',
            icon: Icons.save_outlined,
            height: height,
            onPressed: () {},
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
    });

    testWidgets('given no width, it keeps a gutter around its legend', (tester) async {
      // Arrange — nobody hands it a width, so the label is what it measures itself against. A
      // button that measures itself as exactly its text is a rectangle drawn on the writing.
      await tester.pumpWidget(
        host(
          AppButton(label: label, height: height, onPressed: () {}),
          imposeWidth: false,
        ),
      );

      // Act
      final box = tester.getRect(find.byKey(AppButton.surfaceKey));
      final legend = tester.getRect(find.text(label));

      // Assert — room on both sides, and the label wholly inside the shape.
      expect(box.width, greaterThan(legend.width + 32));
      expect(box.left, lessThan(legend.left));
      expect(box.right, greaterThan(legend.right));
    });

    testWidgets('given a width, it fills it exactly', (tester) async {
      // Arrange — the gutter is a floor, not a margin: it must not shrink a stretched button.
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );

      // Act
      final box = tester.getRect(find.byKey(AppButton.surfaceKey));

      // Assert
      expect(box.width, width);
    });

    testWidgets('a label too long for the button is not painted past its rim', (tester) async {
      // Arrange — a long Arabic label in a narrow box, which is what a small phone does to
      // every one of these strings.
      await tester.pumpWidget(
        host(
          const AppButton(
            label: 'حفظ الأدوار وإرسالها إلى الخادم الآن',
            height: height,
            onPressed: null,
          ),
        ),
      );

      // Act
      final box = tester.getRect(find.byKey(AppButton.surfaceKey));
      final legend = tester.getRect(find.byType(Row).last);

      // Assert — clipped to the shape rather than overflowing it, and no layout exception.
      expect(legend.width, lessThanOrEqualTo(box.width));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the primary variant is filled and has no border', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton(label: label, height: height, onPressed: () {})),
      );

      // Act
      final surface = surfaceOf(tester);

      // Assert
      expect(surface.color, isNot(Colors.transparent));
      expect((surface.shape! as RoundedRectangleBorder).side.width, 0);
    });

    testWidgets('the outlined variant is a border with nothing behind it', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(AppButton.outlined(label: label, height: height, onPressed: () {})),
      );

      // Act
      final surface = surfaceOf(tester);

      // Assert
      expect(surface.color, Colors.transparent);
      expect((surface.shape! as RoundedRectangleBorder).side.width, greaterThan(0));
    });
  });

  group('the width', () {
    testWidgets('it takes everything it is offered, without being told to', (tester) async {
      // Arrange — a centred Column is what a form's footer actually is: it hands its children
      // *loose* constraints, so a button that did not ask for the width used to shrink to fit
      // its label and float in the middle of the phone.
      await tester.pumpWidget(
        host(
          const AppButton(label: label, onPressed: _noop),
          imposeWidth: false,
        ),
      );

      // Act
      final size = tester.getSize(find.byKey(AppButton.surfaceKey));

      // Assert — the whole width it was allowed. The margins around it are the screen's to
      // decide, not the button's.
      expect(size.width, tester.view.physicalSize.width / tester.view.devicePixelRatio);
    });

    testWidgets('a width it was given still wins', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const AppButton(label: label, onPressed: _noop)));

      // Act
      final size = tester.getSize(find.byKey(AppButton.surfaceKey));

      // Assert — `double.infinity` resolves to whatever the parent allows, so an `Expanded` in
      // a Row or a fixed box still decides.
      expect(size.width, width);
    });

    testWidgets('a button asked to measure itself still can', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          const AppButton(label: label, onPressed: _noop, expands: false),
          imposeWidth: false,
        ),
      );

      // Act
      final size = tester.getSize(find.byKey(AppButton.surfaceKey));

      // Assert — narrower than the screen, because it is back to measuring its own legend.
      expect(
        size.width,
        lessThan(tester.view.physicalSize.width / tester.view.devicePixelRatio),
      );
    });
  });
}
