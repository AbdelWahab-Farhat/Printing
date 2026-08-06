import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/views/add_employee_page.dart';
import 'package:printing/features/access/presentation/views/employees_page.dart';
import 'package:printing/features/access/presentation/views/role_detail_page.dart';
import 'package:printing/features/access/presentation/views/role_form_page.dart';
import 'package:printing/features/access/presentation/views/roles_page.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/presentation/views/activity_log_page.dart';
import 'package:printing/features/auth/presentation/views/login_page.dart';
import 'package:printing/features/business_fields/presentation/views/business_fields_page.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/presentation/views/cities_page.dart';
import 'package:printing/features/cities/presentation/views/city_regions_page.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/views/add_customer_page.dart';
import 'package:printing/features/customers/presentation/views/customer_designs_page.dart';
import 'package:printing/features/customers/presentation/views/customer_detail_page.dart';
import 'package:printing/features/customers/presentation/views/customers_page.dart';
import 'package:printing/features/home/presentation/views/home_page.dart';
import 'package:printing/features/location/presentation/views/pick_location_page.dart';
import 'package:printing/features/orders/models/orders_filter.dart';
import 'package:printing/features/orders/presentation/views/filtered_orders_page.dart';
import 'package:printing/features/orders/presentation/views/new_order_page.dart';
import 'package:printing/features/orders/presentation/views/order_detail_page.dart';
import 'package:printing/features/orders/presentation/views/order_edit_page.dart';
import 'package:printing/features/orders/presentation/views/order_payments_page.dart';
import 'package:printing/features/orders/presentation/views/order_status_page.dart';
import 'package:printing/features/orders/presentation/views/orders_page.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/views/product_detail_page.dart';
import 'package:printing/features/products/presentation/views/product_form_page.dart';
import 'package:printing/features/products/presentation/views/products_page.dart';
import 'package:printing/features/root/presentation/views/root_page.dart';
import 'package:printing/features/settings/presentation/views/settings_page.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/presentation/views/shipping_companies_page.dart';
import 'package:printing/features/shipping_companies/presentation/views/shipping_company_form_page.dart';
import 'package:printing/features/splash/presentation/views/splash_page.dart';
import 'package:printing/features/warehouses/models/warehouse.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/presentation/views/stock_movements_page.dart';
import 'package:printing/features/warehouses/presentation/views/warehouse_stocks_page.dart';
import 'package:printing/features/warehouses/presentation/views/warehouses_page.dart';

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

  /// The orders behind one number on the home screen. Takes an [OrdersFilter] as `extra` — the
  /// Arabic title travels with it, because this app deliberately holds no table of status names.
  static const String ordersFiltered = '/orders/filter';
  static const String products = '/products';
  static const String customers = '/customers';

  /// Reached from the drawer and from the home screen's shortcuts. Outside the shell, so the
  /// bottom bar never claims the user is on a tab they have left.
  static const String warehouse = '/warehouse';

  /// The shelves of one warehouse, and the ledger narrowed to it. Declared as children of
  /// `/warehouse`, because that is what they are: a balance has no life outside its place.
  static String warehouseStocks(int warehouseId) => '/warehouse/$warehouseId/stocks';

  static String warehouseMovements(int warehouseId) => '/warehouse/$warehouseId/movements';

  static const String warehouseStocksPath = ':id/stocks';
  static const String warehouseMovementsPath = ':id/movements';

  /// Every movement in the workshop, whatever the place.
  static const String stockMovements = '/stock-movements';
  static const String cities = '/cities';

  /// مجالات العمل — the trades a customer's shop can be in.
  static const String businessFields = '/business-fields';

  /// Who carries our parcels. A flat pair rather than a nested form, because adding a company
  /// is reached from the list *and* — one day — from the dispatch screen when the carrier
  /// somebody wants is not on it yet.
  static const String shippingCompanies = '/shipping-companies';
  static const String shippingCompanyForm = '/shipping-companies/form';

  /// The neighbourhoods inside one city. Declared as a child of `/cities`, because that is what
  /// they are: a region has no life outside its city, and the path saying so matches the API,
  /// where `/cities/{city}/regions/{region}` makes another city's region a 404 by construction.
  static const String cityRegionsPath = ':id/regions';

  static String cityRegions(int cityId) => '/cities/$cityId/regions';

  /// Who works here. Reached from the drawer, and guarded by `users.view`.
  static const String employees = '/employees';

  /// Registering a colleague. Administrators only — see `Session.isAdmin`.
  static const String addEmployee = '/employees/new';

  /// The jobs this business has. A sibling of [employees] rather than a child: a role exists
  /// whether or not anybody holds it, and it is administered by a different permission.
  static const String roles = '/roles';

  /// Creating one. Declared **before** `/roles/:id` below, because GoRouter matches in
  /// declaration order and `:id` would otherwise swallow the word `new`.
  static const String newRole = '/roles/new';

  static const String roleDetailPath = '/roles/:id';

  static String role(int roleId) => '/roles/$roleId';

  /// Editing an existing one — the same screen that creates.
  static const String editRolePath = '/roles/:id/edit';

  static String editRole(int roleId) => '/roles/$roleId/edit';

  /// Preferences, what this build is, and the way out. Outside the shell: it is a place the
  /// user goes *to*, not a tab they browse between.
  static const String settings = '/settings';

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

  /// Taking an order from this customer.
  ///
  /// **A child of the customer, and that is the design rather than a tidy URL.** An order does
  /// not change hands — `customer_id` is read on create and ignored afterwards — so the only
  /// correction for the wrong customer is to cancel the order and take it again. Naming the
  /// customer in the path instead of in a field on the form is what makes the wrong one
  /// unnameable. See NEW-ORDER-DESIGN.md.
  static const String newCustomerOrderPath = 'orders/new';

  static String newCustomerOrder(int customerId) => '/customers/$customerId/orders/new';

  /// Any record's history. One screen for every model — see [AuditSubject].
  static const String activityLogPath = '/logs/:type/:id';

  static String activityLog(AuditSubject subject, int id) => '/logs/${subject.path}/$id';

  static const String addProduct = '/products/new';

  /// The same form, opened on a product that exists. A child of the detail route, because that
  /// is what it is: correcting *this* product.
  static const String editProductPath = 'edit';

  static String editProduct(int productId) => '/products/$productId/edit';

  /// One product, everything about it. Declared **after** `/products/new` below, because
  /// GoRouter matches in declaration order and `:id` would otherwise swallow the word `new`.
  static const String productDetailPath = '/products/:id';

  static String product(int id) => '/products/$id';

  /// One order, everything about it. Outside the shell, because opening an order is a task the
  /// user is *in* — the bottom bar claiming they are still browsing a tab would be wrong.
  static const String orderDetailPath = '/orders/:id';

  static String order(int id) => '/orders/$id';

  /// Moving one order. A screen of its own rather than a sheet, because a destination may ask
  /// for artwork — a picker, an upload, a library — and it pops with the updated order.
  static const String orderStatusPath = 'status';

  static String orderStatus(int id) => '/orders/$id/status';

  /// Changing what an order *says*: its lines, its discount and its artwork. A screen of its
  /// own for the same reason the move is one — it opens pickers and a keyboard, and it pops
  /// with whether anything was written.
  static const String orderEditPath = 'edit';

  static String editOrder(int id) => '/orders/$id/edit';

  /// An order's money: the three numbers, the ledger, and the two ways of writing to it.
  ///
  /// A screen of its own rather than a block on the order, because a ledger gets long — six rows
  /// each carrying a method, a reference, a date and a name is a screen's worth of reading, and
  /// under everything else the order says it was being scrolled past. It pops with whether
  /// anything was written.
  ///
  /// The order's number travels as `extra` so the title can say «#52» without this screen
  /// fetching a whole order to print four characters.
  static const String orderPaymentsPath = 'payments';

  static String orderPayments(int id) => '/orders/$id/payments';

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
      // Guarded like every other screen whose every request would answer 403 without the
      // permission: `can()` answers synchronously, so a deep link cannot open it either.
      GoRoute(
        path: Routes.warehouse,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) => const WarehousesPage(),
        routes: [
          GoRoute(
            path: Routes.warehouseStocksPath,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');

              // A deep link is somebody else's text; `extra` is ours and is absent on one. The
              // screen copes with a missing warehouse — it cannot cope with a missing id.
              return id == null
                  ? const _UnknownWarehouse()
                  : WarehouseStocksPage(
                      warehouseId: id,
                      warehouse: state.extra as Warehouse?,
                    );
            },
          ),
          // The ledger for one place — and, when a shelf hands its own row over as `extra`,
          // for one size in that place. Both are the same list asked a narrower question, so
          // they are one route rather than two.
          GoRoute(
            path: Routes.warehouseMovementsPath,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const _UnknownWarehouse();

              // `extra` is ours and is absent on a deep link, which is exactly why the screen
              // has to work without it: the wider feed is still a correct answer.
              final shelf = state.extra as ({Warehouse? warehouse, WarehouseStock stock})?;

              return StockMovementsPage(
                warehouseId: id,
                warehouseName: shelf?.warehouse?.name,
                stock: shelf?.stock,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.stockMovements,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) => const StockMovementsPage(),
      ),
      // Declared **before** `/orders/:id`, or go_router reads the literal word «filter» as an
      // id and `int.parse` throws — the same trap `/products/new` sits beside.
      GoRoute(
        path: Routes.ordersFiltered,
        builder: (context, state) {
          final filter = state.extra as OrdersFilter?;

          // A deep link carries no `extra`. Rather than an error screen, it answers the widest
          // honest version of the question it was given.
          return FilteredOrdersPage(
            filter: filter ?? const OrdersFilter(title: 'الطلبيات'),
          );
        },
      ),
      // Declared outside the shell and *after* the tab, so `/orders` still selects the tab
      // while `/orders/7` covers it.
      GoRoute(
        path: Routes.orderDetailPath,
        builder: (context, state) => OrderDetailPage(
          orderId: int.parse(state.pathParameters['id']!),
        ),
        routes: [
          // A child of the order, because that is what it is: moving *this* order. No guard of
          // its own — which moves are on offer, and to whom, is a question only the server
          // answers, and the screen shows what it was sent.
          GoRoute(
            path: Routes.orderStatusPath,
            builder: (context, state) => OrderStatusPage(
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: Routes.orderEditPath,
            builder: (context, state) => OrderEditPage(
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
          // Guarded here rather than only on the arm that opens it, so a deep link cannot walk
          // past the check — the API refuses too, and this is what stops the screen 403ing in
          // front of somebody instead of never opening.
          GoRoute(
            path: Routes.orderPaymentsPath,
            redirect: (context, state) => sl<Session>().can(AppPermission.viewOrderPayments)
                ? null
                : Routes.order(int.parse(state.pathParameters['id']!)),
            builder: (context, state) => OrderPaymentsPage(
              orderId: int.parse(state.pathParameters['id']!),
              orderCode: state.extra is String ? state.extra! as String : '',
            ),
          ),
        ],
      ),
      // Declared **before** the list, so the literal word is not captured by a sibling and, as
      // with `/products/new`, guarded on the permission its every request would need.
      GoRoute(
        path: Routes.shippingCompanyForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageShippingCompanies) ? null : Routes.shippingCompanies,
        builder: (context, state) =>
            ShippingCompanyFormPage(company: state.extra as ShippingCompany?),
      ),
      GoRoute(
        path: Routes.shippingCompanies,
        builder: (context, state) => const ShippingCompaniesPage(),
      ),
      // Reading is granted to every role, so the route carries no guard of its own; the screen
      // hides the controls a reader cannot use, and the server refuses either way.
      GoRoute(
        path: Routes.businessFields,
        builder: (context, state) => const BusinessFieldsPage(),
      ),
      GoRoute(
        path: Routes.cities,
        builder: (context, state) => const CitiesPage(),
        routes: [
          GoRoute(
            path: Routes.cityRegionsPath,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');

              // A deep link is somebody else's text; `extra` is ours and is absent on one.
              // The screen copes with a missing city — it cannot cope with a missing id.
              return id == null
                  ? const _UnknownCity()
                  : CityRegionsPage(cityId: id, city: state.extra as City?);
            },
          ),
        ],
      ),
      // Access management. Guarded the same way `/products/new` is: `can()` answers
      // synchronously, so a deep link, a notification tap or a stale back-stack entry cannot
      // open a screen whose every request would answer 403.
      // Declared **before** `/employees`, so the more specific path is not shadowed — and with
      // the stricter guard, because creating an account is the administrator's alone while
      // reading the list is a permission anyone may be granted.
      GoRoute(
        path: Routes.addEmployee,
        // The only route in this file guarded by a role rather than a permission. The server
        // enforces it with a gate ability that cannot be ticked onto a role; this is the
        // matching courtesy, so a deep link cannot open a form whose only ending is a 403.
        redirect: (context, state) => sl<Session>().isAdmin ? null : Routes.home,
        builder: (context, state) => const AddEmployeePage(),
      ),
      GoRoute(
        path: Routes.employees,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewUsers) ? null : Routes.home,
        builder: (context, state) => const EmployeesPage(),
      ),
      GoRoute(
        path: Routes.newRole,
        redirect: _requiresRoleManagement,
        builder: (context, state) => const RoleFormPage(),
      ),
      // After `/roles/new`, and that ordering is load-bearing: go_router matches in declaration
      // order, so `:id` declared first would capture the literal `new` and `int.parse('new')`
      // would throw on the way into the detail screen.
      GoRoute(
        path: Routes.roles,
        redirect: _requiresRoleManagement,
        builder: (context, state) => const RolesPage(),
      ),
      GoRoute(
        path: Routes.roleDetailPath,
        redirect: _requiresRoleManagement,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          return id == null ? const _UnknownRole() : RoleDetailPage(roleId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            // `extra` carries the role the user was just looking at, so the form opens with its
            // name and ticks already in place instead of fetching what the caller already held.
            builder: (context, state) => RoleFormPage(role: state.extra as Role?),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
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
          GoRoute(
            path: 'designs',
            builder: (context, state) => CustomerDesignsPage(
              customerId: int.parse(state.pathParameters['id']!),
              // The name, so the bar can say whose library this is without a second request.
              // Null on a cold deep link, where the heading stands alone.
              customerName: state.extra as String?,
            ),
          ),
          // Guarded here rather than only on the arm that opens it, so a deep link cannot walk
          // past the check — the API refuses too, and this is what stops the form 403ing in
          // front of somebody instead of never opening.
          GoRoute(
            path: Routes.newCustomerOrderPath,
            redirect: (context, state) => sl<Session>().can(AppPermission.manageOrders)
                ? null
                : Routes.customer(int.parse(state.pathParameters['id']!)),
            builder: (context, state) => NewOrderPage(
              customerId: int.parse(state.pathParameters['id']!),
              // The customer the caller was looking at, so the form opens with their name in
              // place. Null on a cold deep link, where the screen fetches them.
              customer: state.extra as Customer?,
            ),
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
        builder: (context, state) => const ProductFormPage(),
      ),
      // After `/products/new`, and that ordering is load-bearing: go_router matches in
      // declaration order, so `:id` declared first would capture the literal `new` and
      // `int.parse('new')` would throw on the way into the detail screen.
      GoRoute(
        path: Routes.productDetailPath,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          // A deep link is somebody else's text. A non-numeric id is a polite screen, not a
          // crash.
          return id == null
              ? const _UnknownProduct()
              : ProductDetailPage(productId: id);
        },
        routes: [
          GoRoute(
            path: Routes.editProductPath,
            redirect: (context, state) =>
                sl<Session>().can(AppPermission.manageProducts) ? null : Routes.products,
            builder: (context, state) {
              // The product travels as `extra` so the form opens filled from the screen that
              // already had it. A deep link carries none, and rather than a blank form
              // pretending to be an edit — which would save an empty product over a real one —
              // it sends the reader to the product itself to open it from there.
              final product = state.extra as Product?;
              final id = int.tryParse(state.pathParameters['id'] ?? '');

              if (product != null) return ProductFormPage(product: product);

              return id == null ? const _UnknownProduct() : ProductDetailPage(productId: id);
            },
          ),
        ],
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

/// Curating roles is one job behind one permission, so all four of its routes ask the same
/// question. Written once here rather than four times inline — a guard that is *almost* the
/// same on one of four routes is the shape this file is trying not to have.
String? _requiresRoleManagement(BuildContext context, GoRouterState state) =>
    sl<Session>().can(AppPermission.manageRoles) ? null : Routes.home;

/// A `/roles/<something that is not a number>` link.
class _UnknownRole extends StatelessWidget {
  const _UnknownRole();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدور')),
      body: const Center(child: Text('رقم الدور غير صحيح')),
    );
  }
}

/// A `/cities/<something that is not a number>/regions` link.
class _UnknownCity extends StatelessWidget {
  const _UnknownCity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المناطق')),
      body: const Center(child: Text('رقم المدينة غير صحيح')),
    );
  }
}

/// A `/warehouse/<something that is not a number>/…` link.
class _UnknownWarehouse extends StatelessWidget {
  const _UnknownWarehouse();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المخزن')),
      body: const Center(child: Text('رقم المخزن غير صحيح')),
    );
  }
}

/// A `/products/<something that is not a number>` link.
class _UnknownProduct extends StatelessWidget {
  const _UnknownProduct();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: const Center(child: Text('رقم المنتج غير صحيح')),
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
