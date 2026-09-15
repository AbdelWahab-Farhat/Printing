import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:go_router/go_router.dart';

/// Every path in the app, named once.
///
/// A route typed as a string at a call site is a route nobody can rename, so `context.go` and
/// `context.push` take a constant from here and never a literal. Functions rather than constants
/// wherever the path carries an id — `Routes.order(7)` cannot be built with the id in the wrong
/// place.
abstract final class Routes {
  static const String home = '/';
}

/// The app's one `GoRouter`.
///
/// **Order matters inside a path.** A literal segment must be registered before the `:id` that
/// would otherwise swallow it — `/orders/archive` above `/orders/:id`, or go_router reads
/// «archive» as an order number and hands it to `int.parse`. The staff app carries that comment
/// on three separate routes; it will be needed here too.
abstract final class AppRouter {
  static final GoRouter instance = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
