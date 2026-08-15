import 'package:dayaa/core/config/app_config.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/attachment_picker_impl.dart';
import 'package:dayaa/core/network/dio_client.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/storage/token_storage.dart';
import 'package:dayaa/features/access/presentation/viewmodel/add_employee_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_form_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/role_detail_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/role_form_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/user_roles_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/repositories/access_repository_impl.dart';
import 'package:dayaa/features/access/usecases/create_role.dart';
import 'package:dayaa/features/access/usecases/create_user.dart';
import 'package:dayaa/features/access/usecases/delete_role.dart';
import 'package:dayaa/features/access/usecases/get_permissions.dart';
import 'package:dayaa/features/access/usecases/get_role.dart';
import 'package:dayaa/features/access/usecases/get_roles.dart';
import 'package:dayaa/features/access/usecases/get_user.dart';
import 'package:dayaa/features/access/usecases/get_users.dart';
import 'package:dayaa/features/access/usecases/set_user_activation.dart';
import 'package:dayaa/features/access/usecases/set_user_password.dart';
import 'package:dayaa/features/access/usecases/set_user_salary.dart';
import 'package:dayaa/features/access/usecases/sync_user_roles.dart';
import 'package:dayaa/features/access/usecases/update_role.dart';
import 'package:dayaa/features/access/usecases/update_user.dart';
import 'package:dayaa/features/audit/repositories/audit_repository.dart';
import 'package:dayaa/features/audit/repositories/audit_repository_impl.dart';
import 'package:dayaa/features/audit/usecases/get_activity_log.dart';
import 'package:dayaa/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';
import 'package:dayaa/features/auth/repositories/auth_repository_impl.dart';
import 'package:dayaa/features/auth/usecases/get_current_user.dart';
import 'package:dayaa/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa/features/auth/usecases/login.dart';
import 'package:dayaa/features/auth/usecases/logout.dart';
import 'package:dayaa/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:dayaa/features/business_fields/presentation/viewmodel/save_business_field_cubit.dart';
import 'package:dayaa/features/business_fields/repositories/business_field_repository.dart';
import 'package:dayaa/features/business_fields/repositories/business_field_repository_impl.dart';
import 'package:dayaa/features/business_fields/usecases/delete_business_field.dart';
import 'package:dayaa/features/business_fields/usecases/get_business_fields.dart';
import 'package:dayaa/features/business_fields/usecases/save_business_field.dart';
import 'package:dayaa/features/business_fields/usecases/set_business_field_activation.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/city_regions_cubit.dart';
import 'package:dayaa/features/cities/repositories/city_repository.dart';
import 'package:dayaa/features/cities/repositories/city_repository_impl.dart';
import 'package:dayaa/features/cities/usecases/get_cities.dart';
import 'package:dayaa/features/cities/usecases/get_city_regions.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dayaa/features/comments/repositories/comment_repository_impl.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository_impl.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/repositories/customer_repository_impl.dart';
import 'package:dayaa/features/customers/usecases/create_customer.dart';
import 'package:dayaa/features/customers/usecases/delete_customer_design.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/get_customer_designs.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:dayaa/features/customers/usecases/rename_customer_design.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:dayaa/features/customers/usecases/update_customer.dart';
import 'package:dayaa/features/customers/usecases/upload_customer_design.dart';
import 'package:dayaa/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:dayaa/features/home/repositories/home_repository.dart';
import 'package:dayaa/features/home/repositories/home_repository_impl.dart';
import 'package:dayaa/features/home/usecases/get_home_summary.dart';
import 'package:dayaa/features/location/presentation/viewmodel/pick_location_cubit.dart';
import 'package:dayaa/features/location/repositories/geocoding_repository.dart';
import 'package:dayaa/features/location/repositories/geocoding_repository_impl.dart';
import 'package:dayaa/features/location/usecases/search_places.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/viewmodel/manufacturing_cost_rates_cubit.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/viewmodel/save_manufacturing_cost_rate_cubit.dart';
import 'package:dayaa/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository.dart';
import 'package:dayaa/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository_impl.dart';
import 'package:dayaa/features/manufacturing_cost_rates/usecases/manufacturing_cost_rate_usecases.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/take_order_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository_impl.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/change_order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:dayaa/features/orders/usecases/record_scrap_loss.dart';
import 'package:dayaa/features/orders/usecases/save_order_invoice_pdf.dart';
import 'package:dayaa/features/orders/usecases/set_order_shortages.dart';
import 'package:dayaa/features/orders/usecases/take_order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_category_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dayaa/features/products/repositories/product_category_repository_impl.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/repositories/product_repository_impl.dart';
import 'package:dayaa/features/products/usecases/delete_product_category.dart';
import 'package:dayaa/features/products/usecases/get_price_quote.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/get_product_categories.dart';
import 'package:dayaa/features/products/usecases/get_products.dart';
import 'package:dayaa/features/products/usecases/reorder_product_categories.dart';
import 'package:dayaa/features/products/usecases/save_product.dart';
import 'package:dayaa/features/products/usecases/save_product_category.dart';
import 'package:dayaa/features/products/usecases/set_product_category_activation.dart';
import 'package:dayaa/features/products/usecases/set_product_category_image.dart';
import 'package:dayaa/features/products/usecases/set_product_stock_unit.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/filtered_purchase_orders_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_orders_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository_impl.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';
import 'package:dayaa/features/reports/repositories/report_repository_impl.dart';
import 'package:dayaa/features/reports/usecases/get_profit_and_loss.dart';
import 'package:dayaa/features/settings/presentation/viewmodel/settings_cubit.dart';
import 'package:dayaa/features/settings/repositories/settings_repository.dart';
import 'package:dayaa/features/settings/repositories/settings_repository_impl.dart';
import 'package:dayaa/features/settings/usecases/get_settings.dart';
import 'package:dayaa/features/settings/usecases/set_notifications_enabled.dart';
import 'package:dayaa/features/shipping_companies/presentation/viewmodel/save_shipping_company_cubit.dart';
import 'package:dayaa/features/shipping_companies/presentation/viewmodel/shipping_companies_cubit.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository_impl.dart';
import 'package:dayaa/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:dayaa/features/shipping_companies/usecases/save_shipping_company.dart';
import 'package:dayaa/features/splash/presentation/viewmodel/splash_cubit.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/save_vendor_cubit.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_detail_cubit.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_purchase_order_counts_cubit.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendors_cubit.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository_impl.dart';
import 'package:dayaa/features/vendors/usecases/get_vendors.dart';
import 'package:dayaa/features/vendors/usecases/save_vendor.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/save_warehouse_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_summary_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouse_stocks_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository_impl.dart';
import 'package:dayaa/features/warehouses/usecases/delete_warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_movements.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_summary.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:dayaa/features/warehouses/usecases/save_warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/set_low_stock_threshold.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
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

  static Future<void> init({
    required Future<void> Function() onUnauthorized,
  }) async {
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
    _registerProductCategories();
    _registerWarehouses();
    _registerVendors();
    _registerPurchaseOrders();
    _registerManufacturingCostRates();
    _registerShippingCompanies();
    _registerCustomers();
    _registerSettings();
    _registerOrders();
    _registerReports();

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
      ..registerLazySingleton<AccessRepository>(
        () => AccessRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetUsers>(() => GetUsers(sl<AccessRepository>()))
      ..registerLazySingleton<CreateUser>(
        () => CreateUser(sl<AccessRepository>()),
      )
      ..registerLazySingleton<GetUser>(() => GetUser(sl<AccessRepository>()))
      ..registerLazySingleton<UpdateUser>(
        () => UpdateUser(sl<AccessRepository>()),
      )
      ..registerLazySingleton<SetUserPassword>(
        () => SetUserPassword(sl<AccessRepository>()),
      )
      ..registerLazySingleton<SetUserSalary>(
        () => SetUserSalary(sl<AccessRepository>()),
      )
      ..registerLazySingleton<SetUserActivation>(
        () => SetUserActivation(sl<AccessRepository>()),
      )
      ..registerLazySingleton<SyncUserRoles>(
        () => SyncUserRoles(sl<AccessRepository>()),
      )
      ..registerLazySingleton<GetRoles>(() => GetRoles(sl<AccessRepository>()))
      ..registerLazySingleton<GetRole>(() => GetRole(sl<AccessRepository>()))
      ..registerLazySingleton<CreateRole>(
        () => CreateRole(sl<AccessRepository>()),
      )
      ..registerLazySingleton<UpdateRole>(
        () => UpdateRole(sl<AccessRepository>()),
      )
      ..registerLazySingleton<DeleteRole>(
        () => DeleteRole(sl<AccessRepository>()),
      )
      ..registerLazySingleton<GetPermissions>(
        () => GetPermissions(sl<AccessRepository>()),
      )
      // Factories: each screen owns its Cubit and closes it on dispose.
      ..registerFactory<UsersCubit>(() => UsersCubit(getUsers: sl<GetUsers>()))
      // Factory: the form owns its Cubit and closes it on dispose. A singleton here would hand
      // the second employee the closed Cubit of the first.
      ..registerFactory<AddEmployeeCubit>(
        () => AddEmployeeCubit(
          getRoles: sl<GetRoles>(),
          createUser: sl<CreateUser>(),
        ),
      )
      ..registerFactory<RolesCubit>(
        () =>
            RolesCubit(getRoles: sl<GetRoles>(), deleteRole: sl<DeleteRole>()),
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
      // Parameterised for the same reason as the role's: the screen is *about* one employee.
      ..registerFactoryParam<EmployeeDetailCubit, int, void>(
        (userId, _) => EmployeeDetailCubit(
          userId: userId,
          getUser: sl<GetUser>(),
          setPassword: sl<SetUserPassword>(),
          setActivation: sl<SetUserActivation>(),
        ),
      )
      ..registerFactory<EmployeeFormCubit>(
        () => EmployeeFormCubit(
          updateUser: sl<UpdateUser>(),
          setSalary: sl<SetUserSalary>(),
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
      ..registerLazySingleton<AuditRepository>(
        () => AuditRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetActivityLog>(
        () => GetActivityLog(sl<AuditRepository>()),
      );
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
      ..registerLazySingleton<GetCurrentUser>(
        () => GetCurrentUser(sl<AuthRepository>()),
      )
      ..registerLazySingleton<Logout>(() => Logout(sl<AuthRepository>()))
      ..registerLazySingleton<HasStoredSession>(
        () => HasStoredSession(sl<AuthRepository>()),
      )
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
            headers: {
              'User-Agent': AppConfig.mapUserAgent,
              'Accept': 'application/json',
            },
          ),
        ),
        instanceName: geocoderDio,
      )
      ..registerLazySingleton<GeocodingRepository>(
        () => GeocodingRepositoryImpl(sl<Dio>(instanceName: geocoderDio)),
      )
      ..registerLazySingleton<SearchPlaces>(
        () => SearchPlaces(sl<GeocodingRepository>()),
      )
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
      ..registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetHomeSummary>(
        () => GetHomeSummary(sl<HomeRepository>()),
      )
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
      ..registerLazySingleton<ProductRepository>(
        () => ProductRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetProducts>(
        () => GetProducts(sl<ProductRepository>()),
      )
      ..registerLazySingleton<GetProduct>(
        () => GetProduct(sl<ProductRepository>()),
      )
      ..registerLazySingleton<SaveProduct>(
        () => SaveProduct(sl<ProductRepository>()),
      )
      // Registered with the catalogue because it is addressed by product id, though the grant it
      // needs is `inventory.manage`: what the shelves count in is an inventory fact about the
      // product rather than a catalogue one.
      ..registerLazySingleton<SetProductStockUnit>(
        () => SetProductStockUnit(sl<ProductRepository>()),
      )
      // Registered with the catalogue rather than with orders, where its only caller lives: it
      // asks the *product* what a quantity costs, and an order is simply the first screen to
      // need the answer.
      ..registerLazySingleton<GetPriceQuote>(
        () => GetPriceQuote(sl<ProductRepository>()),
      )
      // Factory: the catalogue screen owns its Cubit and closes it on dispose.
      ..registerFactory<ProductsCubit>(
        () => ProductsCubit(getProducts: sl<GetProducts>()),
      )
      // Parameterised, like the customer's and the order's: the detail screen is *about* one
      // product, so the id is a construction argument rather than something the Cubit is told
      // afterwards and might be asked for twice with two different answers.
      ..registerFactoryParam<ProductDetailCubit, int, void>(
        (productId, _) => ProductDetailCubit(
          productId: productId,
          getProduct: sl<GetProduct>(),
          setStockUnit: sl<SetProductStockUnit>(),
        ),
      )
      ..registerFactory<SaveProductCubit>(
        () => SaveProductCubit(saveProduct: sl<SaveProduct>()),
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
      ..registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetOrders>(() => GetOrders(sl<OrderRepository>()))
      ..registerLazySingleton<GetOrderCounts>(
        () => GetOrderCounts(sl<OrderRepository>()),
      )
      ..registerLazySingleton<GetOrder>(() => GetOrder(sl<OrderRepository>()))
      // No repository: the invoice is the order the screen already has, drawn. Registered all
      // the same so it is one object per app — it caches the two parsed TrueType faces the PDF
      // embeds, and parsing those per invoice is what makes a share sheet feel slow.
      ..registerLazySingleton<SaveOrderInvoicePdf>(SaveOrderInvoicePdf.new)
      ..registerLazySingleton<TakeOrder>(() => TakeOrder(sl<OrderRepository>()))
      ..registerLazySingleton<UpdateOrderInvoice>(
        () => UpdateOrderInvoice(sl<OrderRepository>()),
      )
      ..registerLazySingleton<ChangeOrderStatus>(
        () => ChangeOrderStatus(sl<OrderRepository>()),
      )
      ..registerLazySingleton<SetOrderShortages>(
        () => SetOrderShortages(sl<OrderRepository>()),
      )
      // Spoiled stock, written off against the line that was being printed. A use case rather
      // than a Cubit because there is no state to hold: the sheet asks twice and pops.
      ..registerLazySingleton<RecordScrapLoss>(
        () => RecordScrapLoss(sl<OrderRepository>()),
      )
      ..registerLazySingleton<AddOrderDesign>(
        () => AddOrderDesign(sl<OrderRepository>()),
      )
      ..registerLazySingleton<ReviewOrderDesign>(
        () => ReviewOrderDesign(sl<OrderRepository>()),
      )
      // An order's money. Its own repository rather than four more methods on the one above,
      // because it is guarded by its own permissions: a screen allowed to read an order is not
      // thereby allowed to read what the customer has paid.
      ..registerLazySingleton<OrderPaymentRepository>(
        () => OrderPaymentRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetOrderLedger>(
        () => GetOrderLedger(sl<OrderPaymentRepository>()),
      )
      ..registerLazySingleton<RecordOrderPayment>(
        () => RecordOrderPayment(sl<OrderPaymentRepository>()),
      )
      ..registerLazySingleton<RefundOrderPayment>(
        () => RefundOrderPayment(sl<OrderPaymentRepository>()),
      )
      ..registerLazySingleton<ReverseOrderPayment>(
        () => ReverseOrderPayment(sl<OrderPaymentRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      // Parameterised on the question it answers: this screen is *about* one filter, so it is
      // a construction argument rather than something the Cubit is told afterwards.
      ..registerFactoryParam<FilteredOrdersCubit, OrdersFilter, void>(
        (filter, _) =>
            FilteredOrdersCubit(getOrders: sl<GetOrders>(), filter: filter),
      )
      ..registerFactory<OrdersCubit>(
        () => OrdersCubit(
          getOrders: sl<GetOrders>(),
          getCounts: sl<GetOrderCounts>(),
        ),
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
      // Parameterised on the order's id, like the detail Cubit beside it and for the same
      // reason: this one is *about* one order's ledger, and a singleton would close on the
      // first order and leave every one after it emitting into a dead stream.
      ..registerFactoryParam<OrderPaymentsCubit, int, void>(
        (orderId, _) => OrderPaymentsCubit(
          orderId: orderId,
          getLedger: sl<GetOrderLedger>(),
          recordPayment: sl<RecordOrderPayment>(),
          refundPayment: sl<RefundOrderPayment>(),
          reversePayment: sl<ReverseOrderPayment>(),
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
      )
      // Parameterised by the *customer*, not by an order — there is no order yet, and the
      // customer is the one thing the form must not be able to change.
      ..registerFactoryParam<TakeOrderCubit, int, void>(
        (customerId, _) =>
            TakeOrderCubit(takeOrder: sl<TakeOrder>(), customerId: customerId),
      )
      // One per line being edited, not one per screen — hence a factory.
      ..registerFactory<LineQuoteCubit>(
        () => LineQuoteCubit(getPriceQuote: sl<GetPriceQuote>()),
      );
  }

  /// التقارير — the figures the business is read by, rather than the records it is made of.
  ///
  /// Registered after the orders block because that is what it reads across; nothing here holds
  /// a reference to it, so the ordering is documentation rather than a dependency.
  ///
  /// No list Cubit and no `PagedCubit`: the report is one object about one period, so there is
  /// no page to ask for.
  static void _registerReports() {
    sl
      ..registerLazySingleton<ReportRepository>(
        () => ReportRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetProfitAndLoss>(
        () => GetProfitAndLoss(sl<ReportRepository>()),
      )
      // Factory: the screen owns its Cubit — the chosen period lives on it — and closes it on
      // dispose.
      ..registerFactory<ProfitAndLossCubit>(
        () => ProfitAndLossCubit(getSummary: sl<GetProfitAndLoss>()),
      );
  }

  /// Cities and their regions — the delivery map. Registered as one block per feature so a new
  /// feature is one method here, not six edits scattered through a 200-line function.
  /// Who carries our parcels.
  ///
  /// Two Cubits from one list: the management screen shows every company, and the dispatch
  /// picker shows only the ones a parcel may still be handed to — so `onlyActive` is a
  /// construction argument rather than a filter the screen has to remember to apply.
  /// الموردون وشحنات التوريد.
  ///
  /// The repository alone for now — the use cases and cubits arrive with the screens that need
  /// them, and registering a `GetVendors` nothing calls would be a factory for dead code. What
  /// this does buy is that the day a screen is written, it reaches the API through the same
  /// front door every other feature does rather than building its own `Dio` call.
  static void _registerVendors() {
    sl
      ..registerLazySingleton<VendorRepository>(
        () => VendorRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetVendors>(
        () => GetVendors(sl<VendorRepository>()),
      )
      ..registerLazySingleton<SaveVendor>(
        () => SaveVendor(sl<VendorRepository>()),
      )
      ..registerLazySingleton<SetVendorActive>(
        () => SetVendorActive(sl<VendorRepository>()),
      )
      // Screen-scoped: the list owns its Cubit and closes it on dispose.
      ..registerFactory<VendorsCubit>(
        () => VendorsCubit(getVendors: sl<GetVendors>()),
      )
      // The picker's own instance, narrowed to the suppliers an order may still be raised
      // against. A named registration rather than a parameter, because a picker asking the
      // same question as the management screen is what it must never do.
      ..registerFactory<VendorsCubit>(
        () => VendorsCubit(getVendors: sl<GetVendors>(), onlyActive: true),
        instanceName: activeVendorsCubit,
      )
      // Parameterised twice: the id it is about, and the row the list already had — which is
      // what lets the screen open filled instead of on a spinner.
      ..registerFactoryParam<VendorDetailCubit, int, Vendor?>(
        (vendorId, initial) => VendorDetailCubit(
          vendorId: vendorId,
          repository: sl<VendorRepository>(),
          setActive: sl<SetVendorActive>(),
          initial: initial,
        ),
      )
      // The numbers on a supplier's screen. Its own Cubit, so a summary that failed leaves the
      // contact details standing — see VendorPurchaseOrderCountsCubit.
      ..registerFactoryParam<VendorPurchaseOrderCountsCubit, int, void>(
        (vendorId, _) => VendorPurchaseOrderCountsCubit(
          vendorId: vendorId,
          getCounts: sl<GetPurchaseOrderCounts>(),
        ),
      )
      ..registerFactory<SaveVendorCubit>(
        () => SaveVendorCubit(
          saveVendor: sl<SaveVendor>(),
          setActive: sl<SetVendorActive>(),
        ),
      );
  }

  /// The picker's [VendorsCubit], as opposed to the management screen's.
  static const String activeVendorsCubit = 'vendors:active';

  static void _registerPurchaseOrders() {
    sl
      ..registerLazySingleton<PurchaseOrderRepository>(
        () => PurchaseOrderRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetPurchaseOrders>(
        () => GetPurchaseOrders(sl<PurchaseOrderRepository>()),
      )
      ..registerLazySingleton<GetPurchaseOrder>(
        () => GetPurchaseOrder(sl<PurchaseOrderRepository>()),
      )
      ..registerLazySingleton<GetPurchaseOrderCounts>(
        () => GetPurchaseOrderCounts(sl<PurchaseOrderRepository>()),
      )
      ..registerLazySingleton<SavePurchaseOrder>(
        () => SavePurchaseOrder(sl<PurchaseOrderRepository>()),
      )
      ..registerLazySingleton<ChangePurchaseOrderStatus>(
        () => ChangePurchaseOrderStatus(sl<PurchaseOrderRepository>()),
      )
      ..registerLazySingleton<ReceivePurchaseOrderArrival>(
        () => ReceivePurchaseOrderArrival(sl<PurchaseOrderRepository>()),
      )
      ..registerFactory<PurchaseOrdersCubit>(
        () => PurchaseOrdersCubit(getOrders: sl<GetPurchaseOrders>()),
      )
      // Parameterised on the id: this screen is *about* one order.
      ..registerFactoryParam<PurchaseOrderDetailCubit, int, void>(
        (purchaseOrderId, _) => PurchaseOrderDetailCubit(
          purchaseOrderId: purchaseOrderId,
          getOrder: sl<GetPurchaseOrder>(),
          changeStatus: sl<ChangePurchaseOrderStatus>(),
          receiveArrival: sl<ReceivePurchaseOrderArrival>(),
        ),
      )
      ..registerFactory<SavePurchaseOrderCubit>(
        () => SavePurchaseOrderCubit(saveOrder: sl<SavePurchaseOrder>()),
      )
      // One fixed question, asked from a supplier's screen. Parameterised on the filter for the
      // same reason the orders one is: the question is settled before the screen opens.
      ..registerFactoryParam<
        FilteredPurchaseOrdersCubit,
        PurchaseOrdersFilter,
        void
      >(
        (filter, _) => FilteredPurchaseOrdersCubit(
          getOrders: sl<GetPurchaseOrders>(),
          filter: filter,
        ),
      );
  }

  /// معدلات تكلفة التصنيع — the standing costs an order is charged when it enters printing.
  ///
  /// Registered beside the purchase orders rather than inside orders, because it is the same
  /// kind of thing the delivery map and مجالات العمل are: reference data curated in one place
  /// and read by everything else.
  ///
  /// Both Cubits are factories: a screen-scoped Cubit registered as a singleton leaves every
  /// later screen emitting into a stream the first one closed.
  static void _registerManufacturingCostRates() {
    sl
      ..registerLazySingleton<ManufacturingCostRateRepository>(
        () => ManufacturingCostRateRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetManufacturingCostRates>(
        () => GetManufacturingCostRates(sl<ManufacturingCostRateRepository>()),
      )
      ..registerLazySingleton<GetManufacturingCostRate>(
        () => GetManufacturingCostRate(sl<ManufacturingCostRateRepository>()),
      )
      ..registerLazySingleton<SaveManufacturingCostRate>(
        () => SaveManufacturingCostRate(sl<ManufacturingCostRateRepository>()),
      )
      ..registerLazySingleton<SetManufacturingCostRateActivation>(
        () => SetManufacturingCostRateActivation(
          sl<ManufacturingCostRateRepository>(),
        ),
      )
      ..registerLazySingleton<DeleteManufacturingCostRate>(
        () =>
            DeleteManufacturingCostRate(sl<ManufacturingCostRateRepository>()),
      )
      ..registerFactory<ManufacturingCostRatesCubit>(
        () => ManufacturingCostRatesCubit(
          getRates: sl<GetManufacturingCostRates>(),
          setRateActivation: sl<SetManufacturingCostRateActivation>(),
          deleteRate: sl<DeleteManufacturingCostRate>(),
        ),
      )
      ..registerFactory<SaveManufacturingCostRateCubit>(
        () => SaveManufacturingCostRateCubit(
          saveRate: sl<SaveManufacturingCostRate>(),
        ),
      );
  }

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
        () =>
            SaveBusinessFieldCubit(saveBusinessField: sl<SaveBusinessField>()),
      );
  }

  /// تصنيفات المنتجات — the headings the catalogue is organised under.
  ///
  /// Registered beside مجالات العمل rather than inside products, because it is the same kind of
  /// thing: a short curated list that other screens pick from.
  static void _registerProductCategories() {
    sl
      ..registerLazySingleton<ProductCategoryRepository>(
        () => ProductCategoryRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetProductCategories>(
        () => GetProductCategories(sl<ProductCategoryRepository>()),
      )
      ..registerLazySingleton<SaveProductCategory>(
        () => SaveProductCategory(sl<ProductCategoryRepository>()),
      )
      ..registerLazySingleton<SetProductCategoryActivation>(
        () => SetProductCategoryActivation(sl<ProductCategoryRepository>()),
      )
      ..registerLazySingleton<DeleteProductCategory>(
        () => DeleteProductCategory(sl<ProductCategoryRepository>()),
      )
      ..registerLazySingleton<ReorderProductCategories>(
        () => ReorderProductCategories(sl<ProductCategoryRepository>()),
      )
      // Not owned by the list's Cubit: setting a picture is the *sheet's* operation, and the
      // sheet is the only thing that knows which file was picked.
      ..registerLazySingleton<SetProductCategoryImage>(
        () => SetProductCategoryImage(sl<ProductCategoryRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<ProductCategoriesCubit>(
        () => ProductCategoriesCubit(
          getCategories: sl<GetProductCategories>(),
          setActivation: sl<SetProductCategoryActivation>(),
          deleteCategory: sl<DeleteProductCategory>(),
          reorderCategories: sl<ReorderProductCategories>(),
        ),
      )
      // The product form's picker and the catalogue's filter both ask for the offered ones
      // only — a stopped heading is one nobody should be able to file under *today*, while the
      // management screen must still see it. A named registration rather than a parameter, so
      // the caller asks for what it means.
      ..registerFactory<ProductCategoriesCubit>(
        () =>
            ProductCategoriesCubit(
                getCategories: sl<GetProductCategories>(),
                setActivation: sl<SetProductCategoryActivation>(),
                deleteCategory: sl<DeleteProductCategory>(),
                reorderCategories: sl<ReorderProductCategories>(),
              )
              ..isActive = true
              // A heading holding subheadings is a heading, not a slot: offering one here would be
              // offering a choice the server refuses with «اختر أحد فروعه».
              ..leafOnly = true,
        instanceName: activeProductCategoriesCubit,
      )
      ..registerFactory<SaveProductCategoryCubit>(
        () => SaveProductCategoryCubit(
          saveCategory: sl<SaveProductCategory>(),
          setImage: sl<SetProductCategoryImage>(),
        ),
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
      ..registerLazySingleton<GetWarehouses>(
        () => GetWarehouses(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<SaveWarehouse>(
        () => SaveWarehouse(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<DeleteWarehouse>(
        () => DeleteWarehouse(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<GetWarehouseStocks>(
        () => GetWarehouseStocks(sl<WarehouseRepository>()),
      )
      ..registerLazySingleton<GetStockSummary>(
        () => GetStockSummary(sl<WarehouseRepository>()),
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
      // Beside the list rather than inside it: the list narrows with the filter and the header
      // above it must not, so they are two Cubits over the same warehouse id.
      ..registerFactoryParam<StockSummaryCubit, int, void>(
        (warehouseId, _) => StockSummaryCubit(
          warehouseId: warehouseId,
          getSummary: sl<GetStockSummary>(),
        ),
      )
      // Two nullable params, because the ledger is read at three zoom levels: the whole
      // workshop, one place, or one size in one place — and the last is what a shelf's own
      // history is.
      ..registerFactoryParam<StockMovementsCubit, int?, int?>(
        (warehouseId, productVariantId) => StockMovementsCubit(
          getMovements: sl<GetStockMovements>(),
          warehouseId: warehouseId,
          productVariantId: productVariantId,
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
      ..registerLazySingleton<CityRepository>(
        () => CityRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetCities>(() => GetCities(sl<CityRepository>()))
      ..registerLazySingleton<GetCityRegions>(
        () => GetCityRegions(sl<CityRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CitiesCubit>(
        () => CitiesCubit(getCities: sl<GetCities>()),
      )
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
      ..registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetCustomers>(
        () => GetCustomers(sl<CustomerRepository>()),
      )
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CustomersCubit>(
        () => CustomersCubit(getCustomers: sl<GetCustomers>()),
      )
      // The same Cubit asking the narrower question, for the picker behind «طلبية جديدة» — the
      // العملاء tab is the record and shows everyone, an order is only ever taken for a customer
      // the shop still sells to. Named rather than a second class, exactly like the vendors pair.
      ..registerFactory<CustomersCubit>(
        () =>
            CustomersCubit(getCustomers: sl<GetCustomers>(), onlyActive: true),
        instanceName: activeCustomersCubit,
      )
      ..registerLazySingleton<CreateCustomer>(
        () => CreateCustomer(sl<CustomerRepository>()),
      )
      ..registerLazySingleton<UpdateCustomer>(
        () => UpdateCustomer(sl<CustomerRepository>()),
      )
      ..registerLazySingleton<GetCustomer>(
        () => GetCustomer(sl<CustomerRepository>()),
      )
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
      // The three numbers over «إدارة الطلبات» on the same screen. Its own Cubit rather than
      // three more fields on the one above, because losing the numbers must not blank a page of
      // contact details that arrived fine — see CUSTOMER-ORDERS-SECTION.md §٣.
      //
      // It reaches into the orders feature for `GetOrderCounts`, which is the whole reason that
      // use case takes a `customerId` it was born with: the summary endpoint has always been
      // able to answer about one person.
      ..registerFactoryParam<CustomerOrderCountsCubit, int, void>(
        (customerId, _) => CustomerOrderCountsCubit(
          customerId: customerId,
          getCounts: sl<GetOrderCounts>(),
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
      )
      // ── what staff say to each other about the customer ──────────────────────
      // Its own repository for the same reason the design library has one: everything here is
      // scoped to a single customer and none of it paginates.
      ..registerLazySingleton<CommentRepository>(
        () => CommentRepositoryImpl(sl<Dio>()),
      )
      ..registerLazySingleton<GetComments>(() => GetComments(sl<CommentRepository>()))
      ..registerLazySingleton<AddComment>(() => AddComment(sl<CommentRepository>()))
      ..registerLazySingleton<EditComment>(() => EditComment(sl<CommentRepository>()))
      ..registerLazySingleton<DeleteComment>(() => DeleteComment(sl<CommentRepository>()))
      // Parameterised on the subject rather than an id: the notes screen is about one record,
      // and *which kind* of record is half of what identifies it.
      ..registerFactoryParam<CommentsCubit, CommentSubject, void>(
        (subject, _) => CommentsCubit(
          subject: subject,
          getComments: sl<GetComments>(),
          addComment: sl<AddComment>(),
          editComment: sl<EditComment>(),
          deleteComment: sl<DeleteComment>(),
        ),
      );
  }

  /// The categories a product may actually be filed under today — the stopped ones are absent.
  /// Asked for by the product form's picker and by the catalogue's filter row.
  static const String activeProductCategoriesCubit =
      'product-categories:active';

  /// The customers list narrowed to the ones still being sold to. See `showCustomerPicker`.
  static const String activeCustomersCubit = 'customers:active';

  /// This device's own preferences — no network, no account.
  static void _registerSettings() {
    sl
      ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl<SharedPreferences>()),
      )
      ..registerLazySingleton<GetSettings>(
        () => GetSettings(sl<SettingsRepository>()),
      )
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
