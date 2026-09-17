import 'package:dayaa_client/core/config/app_config.dart';
import 'package:dayaa_client/core/network/auth_interceptor.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Builds the one `Dio` the whole app shares.
///
/// One instance, registered in the injector: a second `Dio()` created inside a data source
/// would silently miss the token, the timeouts and the logging, and would work perfectly right
/// up until the first authenticated call.
abstract final class DioClient {
  /// Whether this build prints the wire.
  ///
  /// **The build mode decides, not the flavour**, and the distinction is the whole point.
  /// Bodies here carry the bearer token and, once signed in, real customer records; in a
  /// shipped build those would go to logcat, which on Android is readable over `adb` by anyone
  /// holding the phone. `kDebugMode` is false in release *and* in profile, so neither prints —
  /// and profile is the mode used to measure performance, where a logger would distort the very
  /// timings it reports.
  ///
  /// This used to read `AppConfig.isDev && !kReleaseMode`, which tied it to the flavour and got
  /// it wrong in both directions: a debug build pointed at the production API — now the normal
  /// way to work, since `dev` points at a laptop — printed nothing and could not be debugged,
  /// while a `dev` build compiled in profile mode printed freely.
  ///
  /// The parameter exists so both answers are testable; nothing passes it in production.
  static bool logsTraffic({bool isDebugBuild = kDebugMode}) => isDebugBuild;

  static Dio create({
    required TokenStorage tokens,
    required Future<void> Function() onUnauthorized,

    /// **Only a test passes this.** `flutter test` always runs in debug, so without a seam the
    /// release case could not be exercised through this method at all — and a test that cannot
    /// build the shipped client cannot prove the shipped client stays quiet. Replacing the
    /// guard below with `if (true)` used to leave the suite green; now it does not.
    @visibleForTesting bool isDebugBuild = kDebugMode,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        // **`Accept` only — never a default `Content-Type`.** Dio's own
        // `ImplyContentTypeInterceptor` sets `application/json` for a Map body and
        // `multipart/form-data` with the right boundary for a `FormData` one. A hard-coded
        // default wins over it, so every upload in the app was being handed to the JSON
        // encoder, which threw before the request ever left the phone — a `DioException` of
        // type `unknown` carrying no message, on a body the server never saw.
        headers: {'Accept': 'application/json'},
        // 4xx must reach the interceptors and `safeRequest` as a DioException carrying the
        // body — that body is where the API's Arabic message and field errors are.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        /*
         * **`status[]=a&status[]=b`, not `status=a&status=b`.** Dio's default is the second,
         * and PHP throws all but the last value away — so a filter for four values reaches the
         * API as a filter for *one*, and the list comes back narrowed to whichever happened to
         * be sent last. That is not hypothetical: it shipped once in the staff app, where a
         * status filter counted four orders and showed none of them.
         *
         * Set on the shared client rather than per request, because every repeatable filter
         * this API has needs it and the next one will be written by somebody who never met
         * this bug.
         */
        listFormat: ListFormat.multiCompatible,
      ),
    );

    dio.interceptors.add(AuthInterceptor(tokens, onUnauthorized: onUnauthorized));

    // Never in a shipped build — see [logsTraffic] for why the build mode decides this and the
    // flavour does not.
    if (logsTraffic(isDebugBuild: isDebugBuild)) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: true,
          // Wider than the default 90 so a long URL and its `Time: N ms` stay on one line.
          //
          // **Timing comes from the logger, which is why no interceptor here measures it.** The
          // package stamps the request on the way out and subtracts on the way back, printing
          // `Time: N ms` on every response — and on a 4xx/5xx, which arrives as a
          // `DioExceptionType.badResponse`.
          //
          // **It is silent on the failures where the number would matter most.** A timeout or a
          // dropped connection takes the `else` branch of its `onError` and prints only the
          // exception type — so the request that hung for the full 20-second receive timeout is
          // the one that reports nothing. If that number is ever wanted, it needs an
          // interceptor of our own; the logger will not give it.
          maxWidth: 120,
        ),
      );
    }

    return dio;
  }
}
