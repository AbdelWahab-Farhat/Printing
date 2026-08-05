import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/core/config/app_config.dart';
import 'package:printing/core/files/attachment_picker.dart';
import 'package:printing/core/files/attachment_picker_impl.dart';
import 'package:printing/core/network/dio_client.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';
import 'package:printing/features/access/presentation/viewmodel/add_employee_cubit.dart';
import 'package:printing/features/access/presentation/viewmodel/role_detail_cubit.dart';
import 'package:printing/features/access/presentation/viewmodel/role_form_cubit.dart';
import 'package:printing/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:printing/features/access/presentation/viewmodel/user_roles_cubit.dart';
import 'package:printing/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/repositories/access_repository_impl.dart';
import 'package:printing/features/access/usecases/create_role.dart';
import 'package:printing/features/access/usecases/create_user.dart';
import 'package:printing/features/access/usecases/delete_role.dart';
import 'package:printing/features/access/usecases/get_permissions.dart';
import 'package:printing/features/access/usecases/get_role.dart';
import 'package:printing/features/access/usecases/get_roles.dart';
import 'package:printing/features/access/usecases/get_users.dart';
import 'package:printing/features/access/usecases/sync_user_roles.dart';
import 'package:printing/features/access/usecases/update_role.dart';
import 'package:printing/features/audit/repositories/audit_repository.dart';
import 'package:printing/features/audit/repositories/audit_repository_impl.dart';
import 'package:printing/features/audit/usecases/get_activity_log.dart';
import 'package:printing/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';
import 'package:printing/features/auth/repositories/auth_repository_impl.dart';
import 'package:printing/features/auth/usecases/get_current_user.dart';
import 'package:printing/features/auth/usecases/has_stored_session.dart';
import 'package:printing/features/auth/usecases/login.dart';
import 'package:printing/features/auth/usecases/logout.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/save_business_field_cubit.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository_impl.dart';
import 'package:printing/features/business_fields/usecases/delete_business_field.dart';
import 'package:printing/features/business_fields/usecases/get_business_fields.dart';
import 'package:printing/features/business_fields/usecases/save_business_field.dart';
import 'package:printing/features/business_fields/usecases/set_business_field_activation.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:printing/features/cities/presentation/viewmodel/city_regions_cubit.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';
import 'package:printing/features/cities/repositories/city_repository_impl.dart';
import 'package:printing/features/cities/usecases/get_cities.dart';
import 'package:printing/features/cities/usecases/get_city_regions.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/repositories/customer_design_repository.dart';
import 'package:printing/features/customers/repositories/customer_design_repository_impl.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/repositories/customer_repository_impl.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';
import 'package:printing/features/customers/usecases/delete_customer_design.dart';
import 'package:printing/features/customers/usecases/get_customer.dart';
import 'package:printing/features/customers/usecases/get_customer_designs.dart';
import 'package:printing/features/customers/usecases/get_customers.dart';
import 'package:printing/features/customers/usecases/rename_customer_design.dart';
import 'package:printing/features/customers/usecases/save_design_to_device.dart';
import 'package:printing/features/customers/usecases/set_customer_activation.dart';
import 'package:printing/features/customers/usecases/update_customer.dart';
import 'package:printing/features/customers/usecases/upload_customer_design.dart';
import 'package:printing/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:printing/features/home/repositories/home_repository.dart';
import 'package:printing/features/home/repositories/home_repository_impl.dart';
import 'package:printing/features/home/usecases/get_home_summary.dart';
import 'package:printing/features/location/presentation/viewmodel/pick_location_cubit.dart';
import 'package:printing/features/location/repositories/geocoding_repository.dart';
import 'package:printing/features/location/repositories/geocoding_repository_impl.dart';
import 'package:printing/features/location/usecases/search_places.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/orders_filter.dart';
import 'package:printing/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/repositories/order_repository_impl.dart';
import 'package:printing/features/orders/usecases/change_order_status.dart';
import 'package:printing/features/orders/usecases/get_order.dart';
import 'package:printing/features/orders/usecases/get_order_counts.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';
import 'package:printing/features/orders/usecases/manage_order_designs.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';
import 'package:printing/features/products/presentation/viewmodel/add_product_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/repositories/product_repository_impl.dart';
import 'package:printing/features/products/usecases/create_product.dart';
import 'package:printing/features/products/usecases/get_product.dart';
import 'package:printing/features/products/usecases/get_products.dart';
import 'package:printing/features/settings/presentation/viewmodel/settings_cubit.dart';
import 'package:printing/features/settings/repositories/settings_repository.dart';
import 'package:printing/features/settings/repositories/settings_repository_impl.dart';
import 'package:printing/features/settings/usecases/get_settings.dart';
import 'package:printing/features/settings/usecases/set_notifications_enabled.dart';
import 'package:printing/features/shipping_companies/presentation/viewmodel/save_shipping_company_cubit.dart';
import 'package:printing/features/shipping_companies/presentation/viewmodel/shipping_companies_cubit.dart';
import 'package:printing/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:printing/features/shipping_companies/repositories/shipping_company_repository_impl.dart';
import 'package:printing/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:printing/features/shipping_companies/usecases/save_shipping_company.dart';
import 'package:printing/features/splash/presentation/viewmodel/splash_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/save_warehouse_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/warehouse_stocks_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository_impl.dart';
import 'package:printing/features/warehouses/usecases/delete_warehouse.dart';
import 'package:printing/features/warehouses/usecases/get_stock_movements.dart';
import 'package:printing/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:printing/features/warehouses/usecases/get_warehouses.dart';
import 'package:printing/features/warehouses/usecases/record_stock_movement.dart';
import 'package:printing/features/warehouses/usecases/save_warehouse.dart';
import 'package:printing/features/warehouses/usecases/set_low_stock_threshold.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

/// Names the geocoder's own `Dio`, so nothing resolves it by accident.
///
/// See `Injector._registerLocation` for why a second client exists at all.
const String geocoderDio = 'geocoder';

/// Wires the object graph. Nothing else in the app calls `GetIt.registerX`.
///
/// **Which registration to use.** The choice is not stylistic — it decides whether two screens
/// see the same data:
///
/// | Kind | Use for | Why |
/// |---|---|---|
/// | `registerSingleton` | things that must exist before `runApp` (Dio, prefs) | already built |
/// | `registerLazySingleton` | repositories, use cases, app-wide Cubits | built once, on first use |
/// | `registerFactory` | screen-scoped Cubits | a fresh one per screen, so a closed Cubit is never reused |
///
/// A screen-scoped Cubit registered as a singleton is the classic bug here: `close()` on the
/// first screen leaves every later one emitting into a dead stream.
abstract final class Injector {
  static bool _isInitialized = false;

  static Future<void> init({required Future<void> Function() onUnauthorized}) async {
    if (_isInitialized) {
      debugPrint('⚠️ Injector already initialised — skipping');

      return;
    }

    final stopwatch = Stopwatch()..start();

    // ── things the rest of the graph needs before it can be built ──────────────
    await AppConfig.load();

    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final tokens = TokenStorage(secureStorage);

    // Warms the in-memory cache so the first request and the first routing guard both have
    // the token without awaiting.
    await tokens.read();

    // Who is signed in and what they may do. Registered here beside the token rather than in
    // `_registerAuth()`, because everything in there serves the auth screens alone while this is
    // the one object every feature reads. It must exist before `Dio`: the interceptor holds it.
    final session = Session();

    sl
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<TokenStorage>(tokens)
      ..registerSingleton<Session>(session)
      ..registerSingleton<Dio>(
        DioClient.create(
          tokens: tokens,
          session: session,
          onUnauthorized: onUnauthorized,
          // Resolved lazily inside the closure, not captured: the repository is registered
          // further down and does not exist yet at this line.
          refreshSession: () => sl<AuthRepository>().currentUser().then((_) {}),
        ),
      )
      // Getting files off the device. Registered here rather than in a feature block because
      // nothing about it is a feature's: the same picker serves a customer's designs today and
      // an order's attachments next. Behind its interface so a widget test can substitute one
      // — both packages answer through a platform channel that does not exist under
      // `flutter_test`, so the real one would hang there.
      ..registerLazySingleton<AttachmentPicker>(AttachmentPickerImpl.new);

    _registerAccess();
    _registerAudit();
    _registerAuth();
    _registerLocation();
    _registerHome();
    _registerProducts();
    _registerCities();
    _registerBusinessFields();
    _registerWarehouses();
    _registerShippingCompanies();
    _registerCustomers();
    _registerSettings();
    _registerOrders();

    _isInitialized = true;
    debugPrint('⏱️ injector ready in ${stopwatch.elapsed}');
  }

  /// Who works here, what jobs exist, and what each job may do.
  ///
  /// One repository for both halves, because they are one screenful of the business: a role
  /// exists to be given to somebody, and the only thing this app changes about a person is
  /// which roles they hold.
  static void _registerAccess() {
    sl
      ..registerLazySingleton<AccessRepository>(() => AccessRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetUsers>(() => GetUsers(sl<AccessRepository>()))
      ..registerLazySingleton<CreateUser>(() => CreateUser(sl<AccessRepository>()))
      ..registerLazySingleton<SyncUserRoles>(() => SyncUserRoles(sl<AccessRepository>()))
      ..registerLazySingleton<GetRoles>(() => GetRoles(sl<AccessRepository>()))
      ..registerLazySingleton<GetRole>(() => GetRole(sl<AccessRepository>()))
      ..registerLazySingleton<CreateRole>(() => CreateRole(sl<AccessRepository>()))
      ..registerLazySingleton<UpdateRole>(() => UpdateRole(sl<AccessRepository>()))
      ..registerLazySingleton<DeleteRole>(() => DeleteRole(sl<AccessRepository>()))
      ..registerLazySingleton<GetPermissions>(() => GetPermissions(sl<AccessRepository>()))
      // Factories: each screen owns its Cubit and closes it on dispose.
      ..registerFactory<UsersCubit>(() => UsersCubit(getUsers: sl<GetUsers>()))
      // Factory: the form owns its Cubit and closes it on dispose. A singleton here would hand
      // the second employee the closed Cubit of the first.
      ..registerFactory<AddEmployeeCubit>(
        () => AddEmployeeCubit(getRoles: sl<GetRoles>(), createUser: sl<CreateUser>()),
      )
      ..registerFactory<RolesCubit>(
        () => RolesCubit(getRoles: sl<GetRoles>(), deleteRole: sl<DeleteRole>()),
      )
      ..registerFactory<RoleFormCubit>(
        () => RoleFormCubit(
          getPermissions: sl<GetPermissions>(),
          createRole: sl<CreateRole>(),
          updateRole: sl<UpdateRole>(),
        ),
      )
      // Parameterised, like the customer's and the order's: the screen is *about* one role.
      ..registerFactoryParam<RoleDetailCubit, int, void>(
        (roleId, _) => RoleDetailCubit(
          roleId: roleId,
          getRole: sl<GetRole>(),
          getPermissions: sl<GetPermissions>(),
        ),
      )
      // Two parameters, and both are needed at construction: which person, and which roles they
      // already hold. The second comes off the row that was tapped rather than from a second
      // request for an answer the list already carried.
      ..registerFactoryParam<UserRolesCubit, int, Set<String>>(
        (userId, initialRoles) => UserRolesCubit(
          userId: userId,
          initialRoles: initialRoles,
          getRoles: sl<GetRoles>(),
          syncUserRoles: sl<SyncUserRoles>(),
        ),
      );
  }

  /// Every record's history. One repository for every model — the API's log endpoints are one
  /// shape, and `AuditSubject` carries the only part that differs.
  ///
  /// No Cubit here: `ActivityLogCubit` is constructed by the screen, because it needs *which*
  /// record and a factory taking two parameters is a worse way to say that than a constructor.
  static void _registerAudit() {
    sl
      ..registerLazySingleton<AuditRepository>(() => AuditRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetActivityLog>(() => GetActivityLog(sl<AuditRepository>()));
  }

  /// Signing in, and the stored session behind it.
  static void _registerAuth() {
    sl
      // Lazy singleton, not a factory: the splash screen and every future sign-out share one
      // repository, and it is stateless apart from the token store it already shares.
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<Dio>(), sl<TokenStorage>(), sl<Session>()),
      )
      ..registerLazySingleton<Login>(() => Login(sl<AuthRepository>()))
      ..registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(sl<AuthRepository>()))
      ..registerLazySingleton<Logout>(() => Logout(sl<AuthRepository>()))
      ..registerLazySingleton<HasStoredSession>(() => HasStoredSession(sl<AuthRepository>()))
      // Factory: the splash screen owns its Cubit. A singleton would keep the result of the
      // first check for the life of the process, which is exactly wrong for a screen whose
      // whole job is to check again.
      ..registerFactory<SplashCubit>(
        () => SplashCubit(
          hasStoredSession: sl<HasStoredSession>(),
          getCurrentUser: sl<GetCurrentUser>(),
          logout: sl<Logout>(),
        ),
      )
      // Factory: the login screen owns its Cubit and closes it on dispose, so a second visit
      // must not be handed the closed one from the first.
      ..registerFactory<LoginCubit>(() => LoginCubit(login: sl<Login>()))
      // Same reasoning, and it matters more here: the drawer that owns this is rebuilt every
      // time the shell is, and a singleton would be closed by the first one to be disposed.
      ..registerFactory<LogoutCubit>(() => LogoutCubit(logout: sl<Logout>()));
  }

  /// The map picker and the place search behind it.
  ///
  /// **The `Dio` here is a second client, and that is the one deliberate exception to "one Dio
  /// in the app".** Read that rule's reason before removing this: it exists so no request
  /// silently misses the bearer token. Here missing it is the *requirement* — the shared
  /// client's `AuthInterceptor` would hand this app's Sanctum token to a public geocoder that
  /// has no business holding it. No interceptors, its own base URL, and a real `User-Agent`,
  /// which the geocoder's policy requires and enforces with a 403.
  static void _registerLocation() {
    sl
      ..registerLazySingleton<Dio>(
        () => Dio(
          BaseOptions(
            baseUrl: AppConfig.geocoderBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {'User-Agent': AppConfig.mapUserAgent, 'Accept': 'application/json'},
          ),
        ),
        instanceName: geocoderDio,
      )
      ..registerLazySingleton<GeocodingRepository>(
        () => GeocodingRepositoryImpl(sl<Dio>(instanceName: geocoderDio)),
      )
      ..registerLazySingleton<SearchPlaces>(() => SearchPlaces(sl<GeocodingRepository>()))
      // Factory: the picker owns its Cubit and closes it on pop.
      ..registerFactory<PickLocationCubit>(
        () => PickLocationCubit(searchPlaces: sl<SearchPlaces>()),
      );
  }

  /// The home screen: who is signed in, and the counts it opens on.
  static void _registerHome() {
    sl
      // The endpoint landed, and this line is the only one that changed: the contract above it
      // and everything above that never knew the numbers were stand-ins.
      ..registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetHomeSummary>(() => GetHomeSummary(sl<HomeRepository>()))
      // Factory: the home screen owns its Cubit and closes it on dispose.
      ..registerFactory<HomeCubit>(
        () => HomeCubit(
          getCurrentUser: sl<GetCurrentUser>(),
          getHomeSummary: sl<GetHomeSummary>(),
        ),
      );
  }

  /// The catalogue — products, their sizes and their price breaks.
  static void _registerProducts() {
    sl
      ..registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetProducts>(() => GetProducts(sl<ProductRepository>()))
      ..registerLazySingleton<GetProduct>(() => GetProduct(sl<ProductRepository>()))
      ..registerLazySingleton<CreateProduct>(() => CreateProduct(sl<ProductRepository>()))
      // Factory: the catalogue screen owns its Cubit and closes it on dispose.
      ..registerFactory<ProductsCubit>(() => ProductsCubit(getProducts: sl<GetProducts>()))
      // Parameterised, like the customer's and the order's: the detail screen is *about* one
      // product, so the id is a construction argument rather than something the Cubit is told
      // afterwards and might be asked for twice with two different answers.
      ..registerFactoryParam<ProductDetailCubit, int, void>(
        (productId, _) =>
            ProductDetailCubit(productId: productId, getProduct: sl<GetProduct>()),
      )
      ..registerFactory<AddProductCubit>(
        () => AddProductCubit(createProduct: sl<CreateProduct>()),
      );
  }

  /// Orders — the workshop's whole workflow.
  ///
  /// The status machine's rules are not registered here and are not in this app at all: the
  /// server sends each order's legal moves with the order, already narrowed to what the
  /// signed-in user may do. A copy of that map in Dart would be a second source of truth that
  /// nothing keeps honest.
  static void _registerOrders() {
    sl
      ..registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetOrders>(() => GetOrders(sl<OrderRepository>()))
      ..registerLazySingleton<GetOrderCounts>(() => GetOrderCounts(sl<OrderRepository>()))
      ..registerLazySingleton<GetOrder>(() => GetOrder(sl<OrderRepository>()))
      ..registerLazySingleton<UpdateOrderInvoice>(
        () => UpdateOrderInvoice(sl<OrderRepository>()),
      )
      ..registerLazySingleton<ChangeOrderStatus>(
        () => ChangeOrderStatus(sl<OrderRepository>()),
      )
      ..registerLazySingleton<AddOrderDesign>(
        () => AddOrderDesign(sl<OrderRepository>()),
      )
      ..registerLazySingleton<ReviewOrderDesign>(
        () => ReviewOrderDesign(sl<OrderRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      // Parameterised on the question it answers: this screen is *about* one filter, so it is
      // a construction argument rather than something the Cubit is told afterwards.
      ..registerFactoryParam<FilteredOrdersCubit, OrdersFilter, void>(
        (filter, _) => FilteredOrdersCubit(
          getOrders: sl<GetOrders>(),
          filter: filter,
        ),
      )
      ..registerFactory<OrdersCubit>(
        () => OrdersCubit(getOrders: sl<GetOrders>(), getCounts: sl<GetOrderCounts>()),
      )
      // Parameterised, like the customer's: the detail screen is *about* one order, so the id
      // is a construction argument rather than something the Cubit is told afterwards.
      // Parameterised on the order itself: the sheet is seeded from what the screen already
      // has, so opening it costs no round trip.
      ..registerFactoryParam<OrderInvoiceCubit, Order, void>(
        (order, _) => OrderInvoiceCubit(
          order: order,
          updateInvoice: sl<UpdateOrderInvoice>(),
        ),
      )
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: sl<GetOrder>(),
          addDesign: sl<AddOrderDesign>(),
          reviewDesign: sl<ReviewOrderDesign>(),
        ),
      )
      // The move screen fetches the order itself rather than being handed one: it is reachable
      // by deep link, and a screen that only works when another filled its hands has a hidden
      // precondition.
      ..registerFactoryParam<OrderStatusCubit, int, void>(
        (orderId, _) => OrderStatusCubit(
          orderId: orderId,
          getOrder: sl<GetOrder>(),
          changeStatus: sl<ChangeOrderStatus>(),
        ),
      );
  }

  /// Cities and their regions — the delivery map. Registered as one block per feature so a new
  /// feature is one method here, not six edits scattered through a 200-line function.
  /// Who carries our parcels.
  ///
  /// Two Cubits from one list: the management screen shows every company, and the dispatch
  /// picker shows only the ones a parcel may still be handed to — so `onlyActive` is a
  /// construction argument rather than a filter the screen has to remember to apply.
  static void _registerShippingCompanies() {
    sl
      ..registerLazySingleton<ShippingCompanyRepository>(
        () => ShippingCompanyRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetShippingCompanies>(
        () => GetShippingCompanies(sl<ShippingCompanyRepository>()),
      )
      ..registerLazySingleton<SaveShippingCompany>(
        () => SaveShippingCompany(sl<ShippingCompanyRepository>()),
      )
      ..registerFactory<ShippingCompaniesCubit>(
        () => ShippingCompaniesCubit(getCompanies: sl<GetShippingCompanies>()),
      )
      // A second registration rather than a parameter, because the caller never chooses: the
      // picker wants the carriers a parcel may still be handed to, always.
      ..registerFactory<ShippingCompaniesCubit>(
        () => ShippingCompaniesCubit(
          getCompanies: sl<GetShippingCompanies>(),
          onlyActive: true,
        ),
        instanceName: 'active-only',
      )
      ..registerFactory<SaveShippingCompanyCubit>(
        () => SaveShippingCompanyCubit(saveCompany: sl<SaveShippingCompany>()),
      );
  }

  /// مجالات العمل — the trades a customer's shop can be in.
  ///
  /// Registered beside the delivery map rather than inside customers, because it is the same
  /// kind of thing: a short curated list that other screens pick from.
  static void _registerBusinessFields() {
    sl
      ..registerLazySingleton<BusinessFieldRepository>(
        () => BusinessFieldRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetBusinessFields>(
        () => GetBusinessFields(sl<BusinessFieldRepository>()),
      )
      ..registerLazySingleton<SaveBusinessField>(
        () => SaveBusinessField(sl<BusinessFieldRepository>()),
      )
      ..registerLazySingleton<SetBusinessFieldActivation>(
        () => SetBusinessFieldActivation(sl<BusinessFieldRepository>()),
      )
      ..registerLazySingleton<DeleteBusinessField>(
        () => DeleteBusinessField(sl<BusinessFieldRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<BusinessFieldsCubit>(
        () => BusinessFieldsCubit(
          getBusinessFields: sl<GetBusinessFields>(),
          setActivation: sl<SetBusinessFieldActivation>(),
          deleteBusinessField: sl<DeleteBusinessField>(),
        ),
      )
      // The customer form's picker asks for the offered fields only — a stopped trade is one
      // nobody should be able to pick *today*, while the management screen must still see it.
      // A named registration rather than a parameter, so the sheet asks for what it means.
      ..registerFactory<BusinessFieldsCubit>(
        () => BusinessFieldsCubit(
          getBusinessFields: sl<GetBusinessFields>(),
          setActivation: sl<SetBusinessFieldActivation>(),
          deleteBusinessField: sl<DeleteBusinessField>(),
        )..isActive = true,
        instanceName: 'active-only',
      )
      ..registerFactory<SaveBusinessFieldCubit>(
        () => SaveBusinessFieldCubit(saveBusinessField: sl<SaveBusinessField>()),
      );
  }

  /// المخزن — the places, the shelves and the ledger.
  ///
  /// One repository for all three, because they are one context: a balance only ever changes
  /// through a movement, and a screen that showed one without the other would be showing half
  /// an answer.
  static void _registerWarehouses() {
    sl
      ..registerLazySingleton<WarehouseRepository>(
        () => WarehouseRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetWarehouses>(() => GetWarehouses(sl<WarehouseRepository>()))
      ..registerLazySingleton<SaveWarehouse>(() => SaveWarehouse(sl<WarehouseRepository>()))
      ..registerLazySingleton<DeleteWarehouse>(
        () => DeleteWarehouse(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<GetWarehouseStocks>(
        () => GetWarehouseStocks(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<SetLowStockThreshold>(
        () => SetLowStockThreshold(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<GetStockMovements>(
        () => GetStockMovements(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<RecordStockMovement>(
        () => RecordStockMovement(sl<WarehouseRepository>()),
      )
      // Factories: each list screen owns its Cubit and closes it on dispose.
      ..registerFactory<WarehousesCubit>(
        () => WarehousesCubit(
          getWarehouses: sl<GetWarehouses>(),
          deleteWarehouse: sl<DeleteWarehouse>(),
        ),
      )
      // Parameterised: the shelves screen is *about* one warehouse, so the id is a construction
      // argument rather than something the Cubit is told afterwards.
      ..registerFactoryParam<WarehouseStocksCubit, int, void>(
        (warehouseId, _) => WarehouseStocksCubit(
          warehouseId: warehouseId,
          getStocks: sl<GetWarehouseStocks>(),
          setThreshold: sl<SetLowStockThreshold>(),
        ),
      )
      // Nullable param: the ledger is either about one place or about all of them.
      ..registerFactoryParam<StockMovementsCubit, int?, void>(
        (warehouseId, _) => StockMovementsCubit(
          getMovements: sl<GetStockMovements>(),
          warehouseId: warehouseId,
        ),
      )
      ..registerFactory<SaveWarehouseCubit>(
        () => SaveWarehouseCubit(saveWarehouse: sl<SaveWarehouse>()),
      )
      ..registerFactory<RecordMovementCubit>(
        () => RecordMovementCubit(recordMovement: sl<RecordStockMovement>()),
      );
  }

  static void _registerCities() {
    sl
      ..registerLazySingleton<CityRepository>(() => CityRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetCities>(() => GetCities(sl<CityRepository>()))
      ..registerLazySingleton<GetCityRegions>(() => GetCityRegions(sl<CityRepository>()))
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CitiesCubit>(() => CitiesCubit(getCities: sl<GetCities>()))
      // Parameterised, like the customer's and the order's: the regions screen is *about* one
      // city, so the id is a construction argument rather than something the Cubit is told
      // afterwards.
      ..registerFactoryParam<CityRegionsCubit, int, void>(
        (cityId, _) => CityRegionsCubit(
          cityId: cityId,
          getCityRegions: sl<GetCityRegions>(),
        ),
      );
  }

  /// Customers, and the shops they sell from. Only creating one is wired so far — the list and
  /// the edit screen land on this same block.
  static void _registerCustomers() {
    sl
      ..registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetCustomers>(() => GetCustomers(sl<CustomerRepository>()))
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CustomersCubit>(
        () => CustomersCubit(getCustomers: sl<GetCustomers>()),
      )
      ..registerLazySingleton<CreateCustomer>(() => CreateCustomer(sl<CustomerRepository>()))
      ..registerLazySingleton<UpdateCustomer>(() => UpdateCustomer(sl<CustomerRepository>()))
      ..registerLazySingleton<GetCustomer>(() => GetCustomer(sl<CustomerRepository>()))
      ..registerLazySingleton<SetCustomerActivation>(
        () => SetCustomerActivation(sl<CustomerRepository>()),
      )
      // Parameterised: the detail screen is *about* one customer, so the id is a construction
      // argument rather than something the Cubit is told after the fact and might be asked for
      // twice with two different answers.
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: sl<GetCustomer>(),
          setActivation: sl<SetCustomerActivation>(),
        ),
      )
      // Factory: the form owns its Cubit and closes it on dispose. A singleton here would hand
      // the second customer the closed Cubit of the first.
      ..registerFactory<AddCustomerCubit>(
        () => AddCustomerCubit(
          createCustomer: sl<CreateCustomer>(),
          updateCustomer: sl<UpdateCustomer>(),
        ),
      )
      // ── the customer's artwork ───────────────────────────────────────────────
      // Its own repository rather than four more methods on `CustomerRepository`: everything
      // here is scoped to one customer, one call is multipart with a progress stream, and
      // nothing here paginates.
      ..registerLazySingleton<CustomerDesignRepository>(
        () => CustomerDesignRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetCustomerDesigns>(
        () => GetCustomerDesigns(sl<CustomerDesignRepository>()),
      )
      ..registerLazySingleton<UploadCustomerDesign>(
        () => UploadCustomerDesign(sl<CustomerDesignRepository>()),
      )
      ..registerLazySingleton<RenameCustomerDesign>(
        () => RenameCustomerDesign(sl<CustomerDesignRepository>()),
      )
      // Not owned by a Cubit: saving a file is a one-shot action with no state to hold — the
      // sheet the OS opens is the state — so the viewer calls it directly.
      ..registerLazySingleton<SaveDesignToDevice>(
        () => SaveDesignToDevice(sl<CustomerDesignRepository>()),
      )
      ..registerLazySingleton<DeleteCustomerDesign>(
        () => DeleteCustomerDesign(sl<CustomerDesignRepository>()),
      )
      // Parameterised on the customer, like the detail screen's: a library is *of* somebody.
      ..registerFactoryParam<CustomerDesignsCubit, int, void>(
        (customerId, _) => CustomerDesignsCubit(
          customerId: customerId,
          getDesigns: sl<GetCustomerDesigns>(),
          uploadDesign: sl<UploadCustomerDesign>(),
          renameDesign: sl<RenameCustomerDesign>(),
          deleteDesign: sl<DeleteCustomerDesign>(),
        ),
      );
  }

  /// This device's own preferences — no network, no account.
  static void _registerSettings() {
    sl
      ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl<SharedPreferences>()),
      )
      ..registerLazySingleton<GetSettings>(() => GetSettings(sl<SettingsRepository>()))
      ..registerLazySingleton<SetNotificationsEnabled>(
        () => SetNotificationsEnabled(sl<SettingsRepository>()),
      )
      // Factory: the settings screen owns its Cubit and closes it on dispose.
      ..registerFactory<SettingsCubit>(
        () => SettingsCubit(
          getSettings: sl<GetSettings>(),
          setNotificationsEnabled: sl<SetNotificationsEnabled>(),
        ),
      );
  }

  /// Tests only. Never called by the running app.
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
  }
}
