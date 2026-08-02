import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/presentation/views/activity_log_page.dart';
import 'package:printing/features/auth/presentation/views/login_page.dart';
import 'package:printing/features/cities/presentation/views/cities_page.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/views/add_customer_page.dart';
import 'package:printing/features/customers/presentation/views/customer_detail_page.dart';
import 'package:printing/features/customers/presentation/views/customers_page.dart';
import 'package:printing/features/home/presentation/views/home_page.dart';
import 'package:printing/features/location/presentation/views/pick_location_page.dart';
import 'package:printing/features/orders/presentation/views/order_detail_page.dart';
import 'package:printing/features/orders/presentation/views/orders_page.dart';
import 'package:printing/features/products/presentation/views/add_product_page.dart';
import 'package:printing/features/products/presentation/views/products_page.dart';
import 'package:printing/features/root/presentation/views/root_page.dart';
import 'package:printing/features/splash/presentation/views/splash_page.dart';

/// Route names, as constants.
///
/// `context.push(Routes.cities)` — never a typed-out `'/cities'`. A path string at a call site
/// is a broken link the compiler cannot see, and it will be found by a tester, not by a build.
abstract final class Routes {
  static const String splash = '/splash';
  static const String login = '/login';

  /// The four tabs inside the shell. Each is the first location of its own branch, so
  /// `context.go(Routes.products)` selects that tab rather than covering the shell.
  static const String home = '/';
  static const String orders = '/orders';
  static const String products = '/products';
  static const String customers = '/customers';

  /// Reached from the drawer and from the home screen's shortcuts. Outside the shell, so the
  /// bottom bar never claims the user is on a tab they have left.
  static const String warehouse = '/warehouse';
  static const String cities = '/cities';

  /// Registering a customer. A path under `/customers` rather than a top-level `/add-customer`,
  /// so the URL says what is being added — and outside the shell, because a form is a task the
  /// user is *in*, not a tab they are browsing.
  static const String addCustomer = '/customers/new';

  /// One customer, everything about them. Declared **after** `/customers/new` below, because
  /// GoRouter matches in declaration order and `:id` would otherwise swallow the word `new`.
  static const String customerDetail = '/customers/:id';

  static String customer(int id) => '/customers/$id';

  /// Editing an existing one. The same screen that registers a customer.
  static const String editCustomerPath = '/customers/:id/edit';

  static String editCustomer(int id) => '/customers/$id/edit';

  /// A customer's artwork.
  static const String customerDesignsPath = '/customers/:id/designs';

  static String customerDesigns(int id) => '/customers/$id/designs';

  /// Any record's history. One screen for every model — see [AuditSubject].
  static const String activityLogPath = '/logs/:type/:id';

  static String activityLog(AuditSubject subject, int id) => '/logs/${subject.path}/$id';

  static const String addProduct = '/products/new';

  /// One order, everything about it. Outside the shell, because opening an order is a task the
  /// user is *in* — the bottom bar claiming they are still browsing a tab would be wrong.
  static const String orderDetailPath = '/orders/:id';

  static String order(int id) => '/orders/$id';

  /// Choosing a point on the map. Outside the shell, and returns a `LatLng` through `pop`.
  static const String pickLocation = '/pick-location';
}

/// The app's navigation.
///
/// GoRouter only: no `Navigator.push(MaterialPageRoute(...))` anywhere. One router means deep
/// links, the Android back button and the browser's history all behave, and every one of those
/// is something an imperative push quietly breaks.
abstract final class AppRouter {
  static final GoRouter instance = GoRouter(
    // Always the splash: it is the one place that decides whether there is a usable session,
    // so no other screen has to guess.
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      // The signed-in app lives inside one shell: a single app bar, a single bottom bar, and a
      // branch per tab. Each branch keeps its own stack, so switching tabs and coming back
      // lands where the user left off instead of rebuilding from the top.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.orders,
                builder: (context, state) => const OrdersPage(),
              ),
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
              GoRoute(
                path: Routes.customers,
                builder: (context, state) => const CustomersPage(),
              ),
            ],
          ),
        ],
      ),

      // Outside the shell on purpose: these are reached from the drawer and cover the tabs, so
      // the bottom bar does not claim the user is still on a tab they have left.
      GoRoute(
        path: Routes.warehouse,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('المخزن')),
          body: ComingSoonPage(title: 'المخزن', icon: AppIcons.warehouse),
        ),
      ),
      // Declared outside the shell and *after* the tab, so `/orders` still selects the tab
      // while `/orders/7` covers it.
      GoRoute(
        path: Routes.orderDetailPath,
        builder: (context, state) => OrderDetailPage(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: Routes.cities,
        builder: (context, state) => const CitiesPage(),
      ),
      // Declared beside them rather than nested under the العملاء branch: `/customers` has no
      // sub-routes, so this is the only thing `/customers/new` can match, and the form covers
      // the tabs instead of leaving a bottom bar the user can wander off through mid-entry.
      GoRoute(
        path: Routes.addCustomer,
        builder: (context, state) => const AddCustomerPage(),
      ),
      // After `/customers/new`, and that ordering is load-bearing: go_router matches in
      // declaration order, so `:id` declared first would capture the literal `new` and
      // `int.parse('new')` would throw on the way into the detail screen.
      GoRoute(
        path: Routes.customerDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          return id == null
              ? const _UnknownCustomer()
              : CustomerDetailPage(customerId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => AddCustomerPage(customer: state.extra as Customer?),
          ),
        ],
      ),
      GoRoute(
        path: Routes.activityLogPath,
        builder: (context, state) {
          final subject = AuditSubject.tryFromPath(state.pathParameters['type']);
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          // A deep link is somebody else's text. An unknown model or a non-numeric id is a
          // polite screen, not a crash.
          return subject == null || id == null
              ? const _UnknownRecord()
              : ActivityLogPage(
                  subject: subject,
                  recordId: id,
                  title: state.extra as String?,
                );
        },
      ),
      GoRoute(
        path: Routes.pickLocation,
        builder: (context, state) => PickLocationPage(initial: state.extra as LatLng?),
      ),
      GoRoute(
        path: Routes.addProduct,
        // The same courtesy as hiding the button, applied to the other way in: a deep link, a
        // notification tap or a stale back-stack entry must not open a two-screen form whose
        // only possible ending is a 403. Expressible only because `can()` answers synchronously
        // — a redirect cannot await.
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageProducts) ? null : Routes.products,
        builder: (context, state) => const AddProductPage(),
      ),
    ],
    // A cold deep link bypasses `initialLocation`, so it can reach a gated route before the
    // splash has filled the session — and an empty session refuses everything, which would
    // bounce the user to a shell with no name on it. Send them through the splash instead,
    // which fills the session and then routes.
    redirect: (context, state) {
      final at = state.matchedLocation;
      if (at == Routes.splash || at == Routes.login) return null;

      if (!sl<Session>().isSignedIn) {
        return sl<TokenStorage>().hasTokenInMemory ? Routes.splash : Routes.login;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('الصفحة غير موجودة\n${state.uri}', textAlign: TextAlign.center)),
    ),
  );
}

/// A `/logs/<a model nobody has>/…` link.
class _UnknownRecord extends StatelessWidget {
  const _UnknownRecord();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السجل')),
      body: const Center(child: Text('لا يوجد سجل لهذا النوع من السجلات')),
    );
  }
}

/// A `/customers/<something that is not a number>` link.
class _UnknownCustomer extends StatelessWidget {
  const _UnknownCustomer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العميل')),
      body: const Center(child: Text('رقم العميل غير صحيح')),
    );
  }
}
