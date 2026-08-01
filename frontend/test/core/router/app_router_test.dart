import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/router/app_router.dart';

/// What each path resolves to, asked of the real router rather than reasoned about.
///
/// The one that needs proving is `/customers/new`: it sits under `/customers`, which is a shell
/// branch, and "does the branch swallow it?" is a question with a silent wrong answer — the
/// button would land on a tab, or on the error page, and only a person tapping it would find
/// out. `findMatch` answers it without building a widget tree.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// Every route a location resolves through, innermost last.
  ///
  /// Flattened, because a shell keeps its branch's matches nested inside its own: reading only
  /// the top level of `RouteMatchList.matches` would see the shell and never the page under it.
  List<RouteBase> matchedRoutes(String location) {
    final flattened = <RouteBase>[];

    void walk(List<RouteMatchBase> matches) {
      for (final match in matches) {
        flattened.add(match.route);
        if (match is ShellRouteMatch) walk(match.matches);
      }
    }

    walk(AppRouter.instance.configuration.findMatch(Uri.parse(location)).matches);

    return flattened;
  }

  test('adding a customer is a route of its own, not the العملاء tab', () {
    // Arrange — `/customers` is a shell branch with no sub-routes, so this path can only be
    // served by the top-level route declared beside it.
    const location = '/customers/new';

    // Act
    final matches = matchedRoutes(location);

    // Assert — it resolves, and to something outside the shell, so the form covers the tabs.
    expect(matches, isNotEmpty);
    expect(
      matches.whereType<GoRoute>().last.path,
      '/customers/new',
      reason: 'the add-customer form must be what /customers/new opens',
    );
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a form is a task the user is in, not a tab they are browsing',
    );
  });

  test('the العملاء tab still resolves, and still inside the shell', () {
    // Arrange — the sibling path must not have been shadowed by the one above.
    const location = '/customers';

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, '/customers');
    expect(matches.whereType<ShellRouteBase>(), isNotEmpty);
  });
}
