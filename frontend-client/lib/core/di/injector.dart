import 'package:dayaa_client/core/config/app_config.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/files/attachment_picker_impl.dart';
import 'package:dayaa_client/core/network/dio_client.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
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
///
/// **One `_registerX()` per feature**, called in [init] in the order the features were built.
/// The staff app's injector is what this grows into; keeping the shape from the first feature
/// means it never has to be reorganised.
abstract final class Injector {
  static bool _isInitialized = false;

  static Future<void> init({
    required Future<void> Function() onUnauthorized,
  }) async {
    if (_isInitialized) {
      debugPrint('⚠️ Injector already initialised — skipping');

      return;
    }

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
      )
      // Getting files off the device. Registered here rather than in a feature block because
      // nothing about it is a feature's. Behind its interface so a widget test can substitute
      // one — both packages answer through a platform channel that does not exist under
      // `flutter_test`, so the real one would hang there.
      ..registerLazySingleton<AttachmentPicker>(AttachmentPickerImpl.new);

    _isInitialized = true;
  }

  /// Tests only. Never called by the running app.
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
  }
}
