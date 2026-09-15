import 'package:dayaa_client/core/router/pop_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// What a screen hands back when nothing popped it on purpose.
///
/// The back gesture — the iOS edge swipe, the Android system back — pops with no result at all,
/// so a screen with something to say cannot say it through `pop`. It says it here instead, and
/// the opener reads it once the screen is gone, whatever made it go.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// What the opener was answered, and what the pushed route saw in the `extra` seat.
  Object? answer;
  Object? payload;

  const row = 'مطبعة النور الحديثة';

  setUp(() {
    answer = null;
    payload = null;
  });

  /// Two screens: one that opens, one that hands back and leaves without popping a result.
  Widget host({Object? extra, bool forResult = true}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  if (!forResult) {
                    await context.push<void>('/detail', extra: extra);

                    return;
                  }
                  answer = await context.pushForResult<String>('/detail', extra: extra);
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            payload = state.payload;

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => context.handBack(row),
                      child: const Text('سلّم'),
                    ),
                    TextButton(
                      onPressed: () => context.handBack(null),
                      child: const Text('تراجع'),
                    ),
                    // No result on the way out — this is exactly what the edge swipe and the
                    // Android back button do.
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('اخرج'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('hands back what the screen left, though nothing popped a result', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tap(tester, 'افتح');

    // Act — the screen says what it has, then is simply left.
    await tap(tester, 'سلّم');
    await tap(tester, 'اخرج');

    // Assert
    expect(answer, row);
  });

  testWidgets('a screen that was only read hands back nothing', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tap(tester, 'افتح');

    // Act
    await tap(tester, 'اخرج');

    // Assert
    expect(answer, isNull);
  });

  testWidgets('the newest word wins, including taking one back', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tap(tester, 'افتح');

    // Act — changed, then changed back to what the list behind already shows.
    await tap(tester, 'سلّم');
    await tap(tester, 'تراجع');
    await tap(tester, 'اخرج');

    // Assert
    expect(answer, isNull);
  });

  testWidgets('the opener\'s own extra still reaches the route', (tester) async {
    // Arrange — the slot takes the `extra` seat, so the route reads its payload instead.
    await tester.pumpWidget(host(extra: 'مطبعة النور'));
    await tester.pumpAndSettle();

    // Act
    await tap(tester, 'افتح');

    // Assert
    expect(payload, 'مطبعة النور');
  });

  testWidgets('handing back where nobody is listening is not an error', (tester) async {
    // Arrange — opened with a plain push: not every opener wants an answer, and the screen has
    // no way of knowing which kind opened it.
    await tester.pumpWidget(host(forResult: false));
    await tester.pumpAndSettle();
    await tap(tester, 'افتح');

    // Act
    await tap(tester, 'سلّم');
    await tap(tester, 'اخرج');

    // Assert
    expect(answer, isNull);
    expect(tester.takeException(), isNull);
  });
}
