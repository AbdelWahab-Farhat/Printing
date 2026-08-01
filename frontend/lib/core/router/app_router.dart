import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/features/auth/presentation/views/login_page.dart';
import 'package:printing/features/cities/presentation/views/cities_page.dart';
import 'package:printing/features/customers/presentation/views/add_customer_page.dart';
import 'package:printing/features/customers/presentation/views/customers_page.dart';
import 'package:printing/features/home/presentation/views/home_page.dart';
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
                builder: (context, state) =>
                    ComingSoonPage(title: 'قائمة الطلبات', icon: AppIcons.orders),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('الصفحة غير موجودة\n${state.uri}', textAlign: TextAlign.center)),
    ),
  );
}
