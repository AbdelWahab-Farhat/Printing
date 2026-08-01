import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/core/config/app_config.dart';
import 'package:printing/core/network/dio_client.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';
import 'package:printing/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';
import 'package:printing/features/auth/repositories/auth_repository_impl.dart';
import 'package:printing/features/auth/usecases/get_current_user.dart';
import 'package:printing/features/auth/usecases/login.dart';
import 'package:printing/features/auth/usecases/logout.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';
import 'package:printing/features/cities/repositories/city_repository_impl.dart';
import 'package:printing/features/cities/usecases/get_cities.dart';
import 'package:printing/features/cities/usecases/get_city_regions.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/repositories/customer_repository_impl.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';
import 'package:printing/features/customers/usecases/get_customers.dart';
import 'package:printing/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:printing/features/home/repositories/home_repository.dart';
import 'package:printing/features/home/repositories/home_repository_impl.dart';
import 'package:printing/features/home/usecases/get_home_summary.dart';
import 'package:printing/features/products/presentation/viewmodel/add_product_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/repositories/product_repository_impl.dart';
import 'package:printing/features/products/usecases/create_product.dart';
import 'package:printing/features/products/usecases/get_products.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

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
      );

    _registerAuth();
    _registerHome();
    _registerProducts();
    _registerCities();
    _registerCustomers();

    _isInitialized = true;
    debugPrint('⏱️ injector ready in ${stopwatch.elapsed}');
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
      // Factory: the login screen owns its Cubit and closes it on dispose, so a second visit
      // must not be handed the closed one from the first.
      ..registerFactory<LoginCubit>(() => LoginCubit(login: sl<Login>()))
      // Same reasoning, and it matters more here: the drawer that owns this is rebuilt every
      // time the shell is, and a singleton would be closed by the first one to be disposed.
      ..registerFactory<LogoutCubit>(() => LogoutCubit(logout: sl<Logout>()));
  }

  /// The home screen: who is signed in, and the counts it opens on.
  static void _registerHome() {
    sl
      // ⚠️ The implementation still answers with placeholder numbers — see
      // [HomeRepositoryImpl]. It is registered against the contract exactly as a real one would
      // be, so the day the endpoint lands this line is the only thing that changes.
      ..registerLazySingleton<HomeRepository>(HomeRepositoryImpl.new)
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
      ..registerLazySingleton<CreateProduct>(() => CreateProduct(sl<ProductRepository>()))
      // Factory: the catalogue screen owns its Cubit and closes it on dispose.
      ..registerFactory<ProductsCubit>(() => ProductsCubit(getProducts: sl<GetProducts>()))
      ..registerFactory<AddProductCubit>(
        () => AddProductCubit(createProduct: sl<CreateProduct>()),
      );
  }

  /// Cities and their regions — the delivery map. Registered as one block per feature so a new
  /// feature is one method here, not six edits scattered through a 200-line function.
  static void _registerCities() {
    sl
      ..registerLazySingleton<CityRepository>(() => CityRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton<GetCities>(() => GetCities(sl<CityRepository>()))
      ..registerLazySingleton<GetCityRegions>(() => GetCityRegions(sl<CityRepository>()))
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CitiesCubit>(
        () => CitiesCubit(getCities: sl<GetCities>(), getCityRegions: sl<GetCityRegions>()),
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
      // Factory: the form owns its Cubit and closes it on dispose. A singleton here would hand
      // the second customer the closed Cubit of the first.
      ..registerFactory<AddCustomerCubit>(
        () => AddCustomerCubit(createCustomer: sl<CreateCustomer>()),
      );
  }

  /// Tests only. Never called by the running app.
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
  }
}
