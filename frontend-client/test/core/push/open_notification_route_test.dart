import 'package:dayaa_client/core/push/open_notification_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// أين يذهب إشعارٌ ضُغط — وأين لا يذهب.
///
/// Arrange - Act - Assert throughout.
void main() {
  GoRouter routerOver(List<String> visited) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) {
          visited.add(state.uri.path);

          return Text('order ${state.pathParameters['id']}');
        },
      ),
    ],
  );

  testWidgets('a route this build knows is pushed over the current screen', (tester) async {
    // Arrange
    final visited = <String>[];
    final router = routerOver(visited);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Act
    openNotificationRoute('/orders/42', router: router);
    await tester.pumpAndSettle();

    // Assert — pushed, so the back button returns to where the customer was.
    expect(find.text('order 42'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('a route this build has never heard of opens nothing', (tester) async {
    // Arrange — an older app against a newer server: the push may name a screen added since.
    // The app simply opening is the honest answer; the router's error page is not.
    final router = routerOver([]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Act
    openNotificationRoute('/wallet/9', router: router);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('home'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
