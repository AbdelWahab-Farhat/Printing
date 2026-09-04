import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/storage/token_storage.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/views/add_employee_page.dart';
import 'package:dayaa/features/access/presentation/views/employee_detail_page.dart';
import 'package:dayaa/features/access/presentation/views/employee_form_page.dart';
import 'package:dayaa/features/access/presentation/views/employees_page.dart';
import 'package:dayaa/features/access/presentation/views/role_detail_page.dart';
import 'package:dayaa/features/access/presentation/views/role_form_page.dart';
import 'package:dayaa/features/access/presentation/views/roles_page.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/audit/presentation/views/activity_log_page.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/auth/presentation/views/login_page.dart';
import 'package:dayaa/features/business_fields/presentation/views/business_fields_page.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/views/cities_page.dart';
import 'package:dayaa/features/cities/presentation/views/city_regions_page.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/views/comments_page.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/views/add_customer_page.dart';
import 'package:dayaa/features/customers/presentation/views/customer_designs_page.dart';
import 'package:dayaa/features/customers/presentation/views/customer_detail_page.dart';
import 'package:dayaa/features/customers/presentation/views/customers_page.dart';
import 'package:dayaa/features/home/presentation/views/home_page.dart';
import 'package:dayaa/features/investor_portal/presentation/views/investor_portal_page.dart';
import 'package:dayaa/features/location/presentation/views/pick_location_page.dart';
import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/views/manufacturing_cost_rate_form_page.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/views/manufacturing_cost_rates_page.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/presentation/views/filtered_orders_page.dart';
import 'package:dayaa/features/orders/presentation/views/new_order_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_edit_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_notes_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_payments_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_status_page.dart';
import 'package:dayaa/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/views/product_categories_page.dart';
import 'package:dayaa/features/products/presentation/views/product_detail_page.dart';
import 'package:dayaa/features/products/presentation/views/product_form_page.dart';
import 'package:dayaa/features/products/presentation/views/product_images_page.dart';
import 'package:dayaa/features/products/presentation/views/products_page.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/filtered_purchase_orders_page.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_order_detail_page.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_order_form_page.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_orders_page.dart';
import 'package:dayaa/features/reports/presentation/views/profit_and_loss_page.dart';
import 'package:dayaa/features/root/presentation/views/inventory_tab_page.dart';
import 'package:dayaa/features/root/presentation/views/root_page.dart';
import 'package:dayaa/features/settings/presentation/views/settings_page.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/presentation/views/shipping_companies_page.dart';
import 'package:dayaa/features/shipping_companies/presentation/views/shipping_company_form_page.dart';
import 'package:dayaa/features/splash/presentation/views/splash_page.dart';
import 'package:dayaa/features/stock_item_groups/presentation/views/stock_item_groups_page.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_item_form_page.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_items_page.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/views/vendor_detail_page.dart';
import 'package:dayaa/features/vendors/presentation/views/vendor_form_page.dart';
import 'package:dayaa/features/vendors/presentation/views/vendors_page.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/views/stock_movements_page.dart';
import 'package:dayaa/features/warehouses/presentation/views/warehouse_stocks_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Route names, as constants.
///
/// `context.push(Routes.cities)` — never a typed-out `'/cities'`. A path string at a call site
/// is a broken link the compiler cannot see, and it will be found by a tester, not by a build.
abstract final class Routes {
  static const String splash = '/splash';
  static const String login = '/login';

  /// The four tabs inside the shell. Each is the first location of its own branch, so
  /// `context.go(Routes.warehouse)` selects that tab rather than covering the shell.
  static const String home = '/';

  /// The investor's whole application.
  ///
  /// **Declared outside the shell**, unlike every tab: reaching [home] builds the bottom
  /// navigation bar and the drawer behind it, which are full of screens an investor must not
  /// have. Conditioning that screen would leave him one bug away from the staff app.
  static const String investorPortal = '/investor';
  static const String orders = '/orders';

  /// The orders behind one number on the home screen. Takes an [OrdersFilter] as `extra` — the
  /// Arabic title travels with it, because this app deliberately holds no table of status names.
  static const String ordersFiltered = '/orders/filter';
  static const String warehouse = '/warehouse';
  static const String customers = '/customers';

  /// Reached from the drawer. Outside the shell, so the bottom bar never claims the user is on
  /// a tab they have left. It held the tab المخزن now has, and they traded places for the plain
  /// reason the workshop gave: the stock is opened every day, the catalogue once in a while.
  static const String products = '/products';

  /// The shelves of one warehouse, and the ledger narrowed to it. Full paths rather than
  /// children of `/warehouse`: the tab's branch keeps the bottom bar under everything nested in
  /// it, and a room of shelves is a place the user goes *to*, not a tab they browse between.
  static String warehouseStocks(int warehouseId) =>
      '/warehouse/$warehouseId/stocks';

  static String warehouseMovements(int warehouseId) =>
      '/warehouse/$warehouseId/movements';

  static const String warehouseStocksPath = '/warehouse/:id/stocks';
  static const String warehouseMovementsPath = '/warehouse/:id/movements';

  /// Every movement in the workshop, whatever the place.
  static const String stockMovements = '/stock-movements';

  /// أصناف المخزون — the shelves themselves: a material at a size, and the only thing a
  /// warehouse now holds a quantity of.
  ///
  /// Flat rather than a child of `/warehouse`, because a shelf is not a warehouse's: two
  /// products at one size draw on one pile, and the same pile is stocked in three rooms. It is
  /// reference data the stock tab points *at*, not a page inside it.
  static const String stockItems = '/stock-items';

  /// Opening a shelf, or correcting one. Takes a `StockItemFormArgs` as `extra` — the shelf
  /// being edited, or the material a new one is filed under.
  ///
  /// Its `GoRoute` is declared **before** [stockItems]'s, and before any future
  /// `/stock-items/:id`, because go_router matches in declaration order and `:id` would read the
  /// literal word «form» as an id. The same trap `/vendors/form` sits beside.
  static const String stockItemForm = '/stock-items/form';

  /// مجموعات الأصناف — the material a shelf is a size of, «كيس شحن» before it has a size.
  ///
  /// A sibling of [stockItems] rather than a parent path with the sizes underneath: a material
  /// holds nothing and is administered on its own, and its sizes arrive inside its own record
  /// rather than from a filtered list — `/stock-items` carries no group filter at all.
  static const String stockItemGroups = '/stock-item-groups';

  /// الأرباح والخسائر. A flat route with no id: the report is about a period the screen itself
  /// chooses, so there is nothing to put in the path.
  static const String profitAndLoss = '/reports/profit-loss';
  static const String cities = '/cities';

  /// مجالات العمل — the trades a customer's shop can be in.
  static const String businessFields = '/business-fields';

  /// تصنيفات المنتجات — the headings the catalogue is organised under.
  static const String productCategories = '/product-categories';

  /// ما تكلّفه ساعة عمل، وتشغيل الآلة، والمصاريف العامة. A flat pair rather than a nested form,
  /// because a rate is reached from its own list and — one day — from the product it is pinned to.
  static const String manufacturingCostRates = '/manufacturing-cost-rates';
  static const String manufacturingCostRateForm =
      '/manufacturing-cost-rates/form';

  /// Who carries our parcels. A flat pair rather than a nested form, because adding a company
  /// is reached from the list *and* — one day — from the dispatch screen when the carrier
  /// somebody wants is not on it yet.
  static const String shippingCompanies = '/shipping-companies';
  static const String shippingCompanyForm = '/shipping-companies/form';

  /// Who we buy from. The form takes the vendor as `extra`, so it opens filled without a second
  /// request for a record the list already has.
  static const String vendors = '/vendors';
  static const String vendorForm = '/vendors/form';

  /// One supplier. Takes the row as `extra` so the screen opens filled.
  static const String vendorDetailPath = '/vendors/:id';

  static String vendor(int vendorId) => '/vendors/$vendorId';

  // ── أوامر الشراء ──────────────────────────────────────────────────────────
  static const String purchaseOrders = '/purchase-orders';

  /// The purchase orders behind one number on a supplier's screen. Takes a [PurchaseOrdersFilter]
  /// as `extra`, so the Arabic title travels with the question — the same arrangement
  /// [ordersFiltered] uses.
  static const String purchaseOrdersFiltered = '/purchase-orders/filter';
  static const String purchaseOrderForm = '/purchase-orders/form';
  static const String purchaseOrderDetailPath = '/purchase-orders/:id';

  static String purchaseOrder(int id) => '/purchase-orders/$id';

  /// The form, opened from a supplier's own screen.
  ///
  /// The vendor rides in `extra` so the picker opens already answered; the id is in the query
  /// as well, so a link that lost its `extra` — a deep link, a restored back stack — still
  /// knows which supplier it is about.
  static String newVendorPurchaseOrder(int vendorId) =>
      '$purchaseOrderForm?vendor=$vendorId';

  /// The same door, named for what it does — the home screen's «مورد جديد» shortcut points at
  /// it, and «open the form on nothing» reads better as its own name than as a bare path.
  static const String addVendor = vendorForm;

  /// The neighbourhoods inside one city. Declared as a child of `/cities`, because that is what
  /// they are: a region has no life outside its city, and the path saying so matches the API,
  /// where `/cities/{city}/regions/{region}` makes another city's region a 404 by construction.
  static const String cityRegionsPath = ':id/regions';

  static String cityRegions(int cityId) => '/cities/$cityId/regions';

  /// Who works here. Reached from the drawer, and guarded by `users.view`.
  static const String employees = '/employees';

  /// Registering a colleague. Administrators only — see `Session.isAdmin`.
  static const String addEmployee = '/employees/new';

  /// One member of staff — what they are, and everything done to their account.
  static const String employeePath = '/employees/:id';

  static String employee(int id) => '/employees/$id';

  /// Correcting their name, email and phone. Not their password, not their roles and not their
  /// wage: each of those is guarded differently and reached its own way.
  static const String editEmployeePath = '/employees/:id/edit';

  static String editEmployee(int id) => '/employees/$id/edit';

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

  /// What staff have written to each other about a customer.
  static const String customerCommentsPath = '/customers/:id/comments';

  static String customerComments(int id) => '/customers/$id/comments';

  /// A supplier's notes. Nested under the supplier exactly as the customer's are, because that
  /// is what the API does and what a link should say.
  static const String vendorCommentsPath = '/vendors/:id/comments';

  static String vendorComments(int id) => '/vendors/$id/comments';

  /// Taking an order from this customer.
  ///
  /// **A child of the customer, and that is the design rather than a tidy URL.** An order does
  /// not change hands — `customer_id` is read on create and ignored afterwards — so the only
  /// correction for the wrong customer is to cancel the order and take it again. Naming the
  /// customer in the path instead of in a field on the form is what makes the wrong one
  /// unnameable. See NEW-ORDER-DESIGN.md.
  static const String newCustomerOrderPath = 'orders/new';

  static String newCustomerOrder(int customerId) =>
      '/customers/$customerId/orders/new';

  /// Any record's history. One screen for every model — see [AuditSubject].
  static const String activityLogPath = '/logs/:type/:id';

  static String activityLog(AuditSubject subject, int id) =>
      '/logs/${subject.path}/$id';

  static const String addProduct = '/products/new';

  /// The same form, opened on a product that exists. A child of the detail route, because that
  /// is what it is: correcting *this* product.
  static const String editProductPath = 'edit';

  /// A product's photographs — the only place they can be changed after it is created.
  ///
  /// A child of the product for the reason the edit form is: it is about *this* product. The
  /// name travels as `extra` so the bar can say whose photos these are without a second
  /// request; a cold deep link carries none and the heading stands alone.
  static const String productImagesPath = 'images';

  static String productImages(int productId) => '/products/$productId/images';

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

  /// Everything written on the order, each note beside the status it was written at.
  ///
  /// The order travels as `extra` because the screen that opens it already holds one — a page
  /// that re-fetched what its caller has in hand would be a request per tap. A deep link brings
  /// nothing and the page loads it itself.
  static const String orderNotesPath = 'notes';

  static String orderNotes(int id) => '/orders/$id/notes';

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
      // Top level, beside the splash and the login screen rather than inside the shell — the
      // investor gets a page and no way out of it.
      GoRoute(
        path: Routes.investorPortal,
        builder: (context, state) => const InvestorPortalPage(),
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
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomePage(),
              ),
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
                path: Routes.warehouse,
                // The tab hides for an account without the grant — see [RootPage] — and this
                // is the boundary behind that courtesy: a deep link, a notification tap or a
                // stale back-stack entry cannot select a tab whose every request would 403.
                redirect: (context, state) =>
                    sl<Session>().can(AppPermission.viewInventory)
                    ? null
                    : Routes.home,
                builder: (context, state) => const InventoryTabPage(),
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

      // Outside the shell on purpose, even though `/warehouse` itself is a tab now: a room of
      // shelves is a place the user goes *to*, so it covers the tabs the way `/orders/:id`
      // does. Guarded each on its own, because there is no guarded parent to inherit from —
      // `can()` answers synchronously, so a deep link cannot open either.
      GoRoute(
        path: Routes.warehouseStocksPath,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
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
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _UnknownWarehouse();

          // `extra` is ours and is absent on a deep link, which is exactly why the screen
          // has to work without it: the wider feed is still a correct answer.
          final shelf =
              state.extra as ({Warehouse? warehouse, WarehouseStock stock})?;

          return StockMovementsPage(
            warehouseId: id,
            warehouseName: shelf?.warehouse?.name,
            stock: shelf?.stock,
          );
        },
      ),
      GoRoute(
        path: Routes.stockMovements,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) => const StockMovementsPage(),
      ),
      // Declared **before** `/stock-items`, and that ordering is load-bearing the day a
      // `/stock-items/:id` joins them: `:id` declared first captures the literal word «form»
      // and `int.parse('form')` throws on the way in. The same trap `/vendors/form` sits beside.
      //
      // Guarded on *managing* inventory rather than viewing it, and it falls back to the list
      // rather than home — the pattern `/vendors/form` and `/products/new` set. A deep link, a
      // notification tap or a stale back-stack entry must not open a form whose only possible
      // ending is a 403, and somebody who may read the shelves should land on them.
      GoRoute(
        path: Routes.stockItemForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageInventory)
            ? null
            : Routes.stockItems,
        builder: (context, state) {
          // `extra` is ours and is absent on a deep link. Both fields are optional anyway —
          // nothing carried means «open a new shelf under no material», which is a real answer.
          final args = state.extra as StockItemFormArgs?;

          return StockItemFormPage(item: args?.item, group: args?.group);
        },
      ),
      // The shelves, and the materials they are sizes of. Outside the shell for the reason
      // `/warehouse/:id/stocks` is: reference data is a place the user goes *to*, and the bottom
      // bar claiming they are still browsing a tab would be wrong. Guarded each on its own,
      // because there is no guarded parent to inherit from.
      GoRoute(
        path: Routes.stockItems,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) => const StockItemsPage(),
      ),
      GoRoute(
        path: Routes.stockItemGroups,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewInventory) ? null : Routes.home,
        builder: (context, state) => const StockItemGroupsPage(),
      ),
      // No `/reports/:id` sibling to be shadowed by, so nothing here is ordering-sensitive.
      // Guarded like every other screen whose every request would answer 403 without the grant.
      GoRoute(
        path: Routes.profitAndLoss,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewProfitAndLossReport)
            ? null
            : Routes.home,
        builder: (context, state) => const ProfitAndLossPage(),
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
        builder: (context, state) =>
            OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
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
            builder: (context, state) =>
                OrderEditPage(orderId: int.parse(state.pathParameters['id']!)),
          ),
          // No guard: the notes are part of the order, and anybody who reached the order has
          // already been allowed to read them.
          GoRoute(
            path: Routes.orderNotesPath,
            builder: (context, state) => OrderNotesPage(
              orderId: int.parse(state.pathParameters['id']!),
              order: state.extra is Order ? state.extra! as Order : null,
            ),
          ),
          // Guarded here rather than only on the arm that opens it, so a deep link cannot walk
          // past the check — the API refuses too, and this is what stops the screen 403ing in
          // front of somebody instead of never opening.
          GoRoute(
            path: Routes.orderPaymentsPath,
            redirect: (context, state) =>
                sl<Session>().can(AppPermission.viewOrderPayments)
                ? null
                : Routes.order(int.parse(state.pathParameters['id']!)),
            builder: (context, state) => OrderPaymentsPage(
              orderId: int.parse(state.pathParameters['id']!),
              orderCode: state.extra is String ? state.extra! as String : '',
            ),
          ),
        ],
      ),
      // Declared **before** the list, so the literal word is not captured by a sibling and,
      // as with `/products/new`, guarded on the permission its every request would need.
      GoRoute(
        path: Routes.vendorForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageVendors)
            ? null
            : Routes.vendors,
        builder: (context, state) =>
            VendorFormPage(vendor: state.extra as Vendor?),
      ),
      GoRoute(
        path: Routes.vendors,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewVendors) ? null : Routes.home,
        builder: (context, state) => const VendorsPage(),
      ),
      // Declared **before** the list and before `:id`, so the literal word «form» is not read
      // as an id — the same trap `/products/new` sits beside.
      GoRoute(
        path: Routes.purchaseOrderForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.managePurchaseOrders)
            ? null
            : Routes.purchaseOrders,
        builder: (context, state) => PurchaseOrderFormPage(
          // Both arrive as `extra` and only one is ever present: an order when the form is
          // opened to correct it, a vendor when it is opened from that supplier's screen.
          order: state.extra is PurchaseOrder
              ? state.extra! as PurchaseOrder
              : null,
          vendor: state.extra is Vendor ? state.extra! as Vendor : null,
        ),
      ),
      GoRoute(
        path: Routes.purchaseOrders,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewPurchaseOrders)
            ? null
            : Routes.home,
        builder: (context, state) => const PurchaseOrdersPage(),
      ),
      // Declared **before** `/purchase-orders/:id`, or go_router reads the literal word
      // «filter» as an id — the same trap `/orders/filter` sits beside.
      GoRoute(
        path: Routes.purchaseOrdersFiltered,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewPurchaseOrders)
            ? null
            : Routes.home,
        builder: (context, state) {
          final filter = state.extra as PurchaseOrdersFilter?;

          // A deep link carries no `extra`. Rather than an error screen, it answers the widest
          // honest version of the question it was given.
          return FilteredPurchaseOrdersPage(
            filter: filter ?? const PurchaseOrdersFilter(title: 'أوامر الشراء'),
          );
        },
      ),
      GoRoute(
        path: Routes.purchaseOrderDetailPath,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewPurchaseOrders)
            ? null
            : Routes.home,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          return id == null
              ? const _UnknownPurchaseOrder()
              : PurchaseOrderDetailPage(purchaseOrderId: id);
        },
      ),
      // After `/vendors/form`, and that ordering is load-bearing: declared first, `:id` would
      // capture the literal word and `int.parse('form')` would throw on the way in.
      // The supplier's notes, nested under the supplier — declared before the detail route so
      // `:id` cannot swallow it, the same ordering `/vendors/form` needs.
      GoRoute(
        path: Routes.vendorCommentsPath,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewVendors) ? null : Routes.home,
        builder: (context, state) => CommentsPage(
          subject: CommentSubject.vendor(int.parse(state.pathParameters['id']!)),
          // Whose notes these are, without a second request. Null on a cold deep link.
          ownerName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: Routes.vendorDetailPath,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewVendors) ? null : Routes.home,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          // A deep link is somebody else's text; `extra` is ours and is absent on one. The
          // screen copes with a missing vendor — it cannot cope with a missing id.
          return id == null
              ? const _UnknownVendor()
              : VendorDetailPage(vendorId: id, vendor: state.extra as Vendor?);
        },
      ),
      // Declared **before** the list, so the literal word is not captured by a sibling and, as
      // with `/products/new`, guarded on the permission its every request would need.
      GoRoute(
        path: Routes.shippingCompanyForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageShippingCompanies)
            ? null
            : Routes.shippingCompanies,
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
      // Guarded on reading the catalogue, which is what its every request needs: the screen
      // hides the controls an account without `products.manage` cannot use, and the server
      // refuses either way.
      GoRoute(
        path: Routes.productCategories,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewProducts) ? null : Routes.home,
        builder: (context, state) => const ProductCategoriesPage(),
      ),
      // Declared **before** the list, so the literal word «form» is not captured by a sibling —
      // the same trap `/products/new` sits beside — and guarded on the permission its every
      // request would need.
      GoRoute(
        path: Routes.manufacturingCostRateForm,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageManufacturingCostRates)
            ? null
            : Routes.manufacturingCostRates,
        // `extra` is ours, and the screen works without it: a cold link opens «معدل تكلفة جديد».
        builder: (context, state) => ManufacturingCostRateFormPage(
          rate: state.extra as ManufacturingCostRate?,
        ),
      ),
      GoRoute(
        path: Routes.manufacturingCostRates,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewManufacturingCostRates)
            ? null
            : Routes.home,
        builder: (context, state) => const ManufacturingCostRatesPage(),
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
        redirect: (context, state) =>
            sl<Session>().isAdmin ? null : Routes.home,
        builder: (context, state) => const AddEmployeePage(),
      ),
      // Before `/employees/:id`, for the reason `/employees/new` is before both: go_router
      // matches in declaration order, and `new` would otherwise be read as an id.
      GoRoute(
        path: Routes.editEmployeePath,
        // `users.manage`, unlike the two above it: reading the list is one permission, and
        // correcting somebody's details is another.
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageUsers) ? null : Routes.home,
        builder: (context, state) {
          // The employee comes through `extra`, which a deep link cannot carry — so a pasted
          // URL lands on the screen that *can* fetch them rather than on an empty form.
          final user = state.extra as AuthUser?;

          return user == null
              ? const _UnknownEmployee()
              : EmployeeFormPage(user: user);
        },
      ),
      GoRoute(
        path: Routes.employees,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewUsers) ? null : Routes.home,
        builder: (context, state) => const EmployeesPage(),
      ),
      GoRoute(
        path: Routes.employeePath,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewUsers) ? null : Routes.home,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          return id == null
              ? const _UnknownEmployee()
              : EmployeeDetailPage(userId: id);
        },
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
            builder: (context, state) =>
                RoleFormPage(role: state.extra as Role?),
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
            builder: (context, state) =>
                AddCustomerPage(customer: state.extra as Customer?),
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
          GoRoute(
            path: 'comments',
            builder: (context, state) => CommentsPage(
              subject: CommentSubject.customer(int.parse(state.pathParameters['id']!)),
              // As above: whose notes these are, without a second request.
              ownerName: state.extra as String?,
            ),
          ),
          // Guarded here rather than only on the arm that opens it, so a deep link cannot walk
          // past the check — the API refuses too, and this is what stops the form 403ing in
          // front of somebody instead of never opening.
          GoRoute(
            path: Routes.newCustomerOrderPath,
            redirect: (context, state) =>
                sl<Session>().can(AppPermission.manageOrders)
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
          final subject = AuditSubject.tryFromPath(
            state.pathParameters['type'],
          );
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
        builder: (context, state) =>
            PickLocationPage(initial: state.extra as LatLng?),
      ),
      // The catalogue itself, reached from the drawer since المخزن took its tab. Guarded on
      // the permission its every request needs, exactly as its drawer row is gated.
      GoRoute(
        path: Routes.products,
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.viewProducts) ? null : Routes.home,
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: Routes.addProduct,
        // The same courtesy as hiding the button, applied to the other way in: a deep link, a
        // notification tap or a stale back-stack entry must not open a two-screen form whose
        // only possible ending is a 403. Expressible only because `can()` answers synchronously
        // — a redirect cannot await.
        redirect: (context, state) =>
            sl<Session>().can(AppPermission.manageProducts)
            ? null
            : Routes.products,
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
          // Guarded on *reading* the catalogue, not on managing it: somebody who may see a
          // product may see its photographs. The three buttons inside are what `products.manage`
          // gates, and the API refuses either way.
          GoRoute(
            path: Routes.productImagesPath,
            redirect: (context, state) =>
                sl<Session>().can(AppPermission.viewProducts) ? null : Routes.home,
            builder: (context, state) => ProductImagesPage(
              productId: int.parse(state.pathParameters['id']!),
              // The name, so the bar can say whose photographs these are without a second
              // request. Null on a cold deep link, where the heading stands alone.
              productName: state.extra as String?,
            ),
          ),
          GoRoute(
            path: Routes.editProductPath,
            redirect: (context, state) =>
                sl<Session>().can(AppPermission.manageProducts)
                ? null
                : Routes.products,
            builder: (context, state) {
              // The product travels as `extra` so the form opens filled from the screen that
              // already had it. A deep link carries none, and rather than a blank form
              // pretending to be an edit — which would save an empty product over a real one —
              // it sends the reader to the product itself to open it from there.
              final product = state.extra as Product?;
              final id = int.tryParse(state.pathParameters['id'] ?? '');

              if (product != null) return ProductFormPage(product: product);

              return id == null
                  ? const _UnknownProduct()
                  : ProductDetailPage(productId: id);
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

      final session = sl<Session>();

      if (!session.isSignedIn) {
        return sl<TokenStorage>().hasTokenInMemory
            ? Routes.splash
            : Routes.login;
      }

      // **An investor never reaches the staff shell.** Placed after the sign-in check because a
      // cold deep link arrives with an empty session, which must go through the splash to be
      // filled first — asking this of an empty session would bounce everybody.
      //
      // Narrowed by «cannot read orders» rather than by a role name, so an administrator who
      // also happens to be an investor still gets the board he came for. And it catches the two
      // places that land on `/` — the splash and the login screen — so neither has to know.
      //
      // A courtesy, never a boundary: the boundary is `can:investor_portal.view` on the route
      // and the query behind it.
      if (session.isInvestor &&
          !session.can(AppPermission.viewOrders) &&
          at != Routes.investorPortal) {
        return Routes.investorPortal;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'الصفحة غير موجودة\n${state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
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
/// A `/purchase-orders/<something that is not a number>` link.
class _UnknownPurchaseOrder extends StatelessWidget {
  const _UnknownPurchaseOrder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أمر الشراء')),
      body: const Center(child: Text('رقم أمر الشراء غير صحيح')),
    );
  }
}

/// A `/vendors/<something that is not a number>` link.
class _UnknownVendor extends StatelessWidget {
  const _UnknownVendor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المورد')),
      body: const Center(child: Text('رقم المورد غير صحيح')),
    );
  }
}

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

/// An `/employees/<something that is not a number>` link, or an edit form reached without the
/// employee it is meant to edit — the second happens only on a pasted URL, since every button
/// that opens it hands the record over in `extra`.
class _UnknownEmployee extends StatelessWidget {
  const _UnknownEmployee();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموظف')),
      body: const Center(child: Text('لم يُحدَّد الموظف')),
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
