import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/core/config/app_config.dart';
import 'package:printing/core/network/dio_client.dart';
import 'package:printing/core/storage/token_storage.dart';
import 'package:printing/features/cities/data/datasources/city_remote_data_source.dart';
import 'package:printing/features/cities/data/repositories/city_repository_impl.dart';
import 'package:printing/features/cities/domain/repositories/city_repository.dart';
import 'package:printing/features/cities/domain/usecases/get_cities.dart';
import 'package:printing/features/cities/domain/usecases/get_city_regions.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';
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

    sl
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<TokenStorage>(tokens)
      ..registerSingleton<Dio>(
        DioClient.create(tokens: tokens, onUnauthorized: onUnauthorized),
      );

    _registerCities();

    _isInitialized = true;
    debugPrint('⏱️ injector ready in ${stopwatch.elapsed}');
  }

  /// Cities and their regions — the delivery map. Registered as one block per feature so a new
  /// feature is one method here, not six edits scattered through a 200-line function.
  static void _registerCities() {
    sl
      ..registerLazySingleton<CityRemoteDataSource>(() => CityRemoteDataSource(sl<Dio>()))
      ..registerLazySingleton<CityRepository>(
        () => CityRepositoryImpl(sl<CityRemoteDataSource>()),
      )
      ..registerLazySingleton<GetCities>(() => GetCities(sl<CityRepository>()))
      ..registerLazySingleton<GetCityRegions>(() => GetCityRegions(sl<CityRepository>()))
      // Factory: the list screen owns its Cubit and closes it on dispose.
      ..registerFactory<CitiesCubit>(
        () => CitiesCubit(getCities: sl<GetCities>(), getCityRegions: sl<GetCityRegions>()),
      );
  }

  /// Tests only. Never called by the running app.
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
  }
}
