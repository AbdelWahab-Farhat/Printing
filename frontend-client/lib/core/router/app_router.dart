import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/features/auth/presentation/views/login_page.dart';
import 'package:dayaa_client/features/auth/presentation/views/profile_page.dart';
import 'package:dayaa_client/features/auth/presentation/views/register_page.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/catalog/presentation/views/product_detail_page.dart';
import 'package:dayaa_client/features/catalog/presentation/views/products_page.dart';
import 'package:dayaa_client/features/designs/presentation/views/designs_page.dart';
import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/place_order_page.dart';
import 'package:dayaa_client/features/support/presentation/views/support_page.dart';
import 'package:dayaa_client/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa_client/features/tools/presentation/views/bag_preview_page.dart';
import 'package:dayaa_client/features/tools/presentation/views/qr_tool_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Every path in the app, named once.
///
/// A route typed as a string at a call site is a route nobody can rename, so `context.go` and
/// `context.push` take a constant from here and never a literal. Functions rather than constants
/// wherever the path carries an id — `Routes.order(7)` cannot be built with the id in the wrong
/// place.
abstract final class Routes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  static const String products = '/products';

  static String product(int id) => '/products/$id';

  static const String designs = '/designs';

  static const String orders = '/orders';

  /// Composing one. **A literal segment under `/orders`**, which is why it is registered before
  /// `:id` below — go_router would otherwise read «new» as an order number.
  static const String newOrder = '/orders/new';

  static String order(int id) => '/orders/$id';

  static const String profile = '/profile';

  static const String support = '/support';

  /// «الدعم», with a new thread already pointed at an order.
  ///
  /// **A query parameter rather than `extra`.** It rides in the location itself, so it survives
  /// anything the router does to the route — and it is readable in a log when somebody asks why
  /// a ticket came in attached to the wrong order. `int.tryParse` on the far side means a
  /// malformed value is simply no order rather than a crash.
  static String supportAbout(int orderId) => '/support?order=$orderId';

  static String ticket(int id) => '/support/$id';

  /// The QR tool, opened to be used.
  static const String qrTool = '/tools/qr';

  /// «معاينة على الكيس» — the artwork on a picture of the bag it will be printed on.
  static const String bagPreview = '/tools/bag-preview';

  /// **The same screen, with another ending**: it hands the code back as a *file* to whoever
  /// opened it, instead of giving it to the system's share sheet. That is what makes the tool
  /// part of the app rather than a second app inside it — «تصاميمي» opens it the way it opens
  /// the camera, and what comes back goes through the same upload.
  static const String qrToolPick = '/tools/qr/pick';
}

/// The app's one `GoRouter`.
///
/// **Order matters inside a path.** A literal segment must be registered before the `:id` that
/// would otherwise swallow it — `/orders/new` above `/orders/:id`, or go_router reads «new» as
/// an order number and hands it to `int.parse`.
///
/// **The five sections live in a shell, the rest are pushed over it.** A customer moving between
/// «المنتجات» and «طلباتي» is switching what they are looking at, not going deeper — so those
/// keep their scroll position and their bottom bar. A product, an order, a thread: those are
/// somewhere you go and come back from, so they cover the bar and carry a back button.
abstract final class AppRouter {
  static final GoRouter instance = GoRouter(
    initialLocation: Routes.home,
    redirect: _guard,
    routes: [
      GoRoute(path: Routes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterPage()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.products,
                builder: (context, state) => const ProductsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.orders, builder: (context, state) => const OrdersPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.designs, builder: (context, state) => const DesignsPage()),
            ],
          ),
          // **«حسابي» is the fifth tab, not «الدعم».** Support is reached from the home
          // screen's «الخدمات» group — it is somewhere you go when something is wrong, which is
          // not often enough to hold a permanent seat.
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.profile, builder: (context, state) => const ProfilePage()),
            ],
          ),
        ],
      ),

      // ── pushed over the shell ────────────────────────────────────────────────
      GoRoute(path: Routes.support, builder: (context, state) => const SupportPage()),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) =>
            ProductDetailPage(productId: int.parse(state.pathParameters['id']!)),
      ),

      /// **Registered before `/orders/:id`**, so `/orders/new` is not read as an order whose id
      /// is «new».
      ///
      /// The lines used to travel in `extra` — a list of objects, and a URL is not a place to
      /// put one. They come out of the basket now, so the route carries nothing and the screen
      /// can be reached from anywhere, including a cold link.
      GoRoute(
        path: Routes.newOrder,
        builder: (context, state) => const PlaceOrderPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
      ),

      // **Before `/tools/qr`**, since the literal «pick» would otherwise never be reached if a
      // parameterised sibling were ever added under it.
      GoRoute(
        path: Routes.qrToolPick,
        builder: (context, state) => const QrToolPage.picking(),
      ),
      GoRoute(path: Routes.qrTool, builder: (context, state) => const QrToolPage()),
      GoRoute(
        path: Routes.bagPreview,
        builder: (context, state) => const BagPreviewPage(),
      ),

      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            TicketThreadPage(ticketId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );

  /// Where somebody without a token is allowed to be.
  static const Set<String> _public = {Routes.login, Routes.register};

  /// Sends a signed-out customer to the sign-in screen, and a signed-in one away from it.
  ///
  /// **Synchronous, and it only ever asks whether a token exists** — never whether it is good.
  /// `redirect` cannot await, and a guard that tried to check the token with the server would
  /// have to block every navigation on a round trip. Whether the token is still valid is
  /// answered by the first request that uses it: `AuthInterceptor` turns a 401 into the
  /// `onUnauthorized` callback, which clears the session and lands back here.
  static String? _guard(BuildContext context, GoRouterState state) {
    final signedIn = sl<HasStoredSession>()();
    final isPublic = _public.contains(state.matchedLocation);

    if (!signedIn && !isPublic) return Routes.login;

    // Somebody holding a token has no business on the sign-in screen — a back button that
    // returns to it after signing in is how a customer ends up signing in twice.
    if (signedIn && isPublic) return Routes.home;

    return null;
  }
}
