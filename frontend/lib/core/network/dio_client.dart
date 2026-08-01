import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:printing/core/config/app_config.dart';
import 'package:printing/core/network/auth_interceptor.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';

/// Builds the one `Dio` the whole app shares.
///
/// One instance, registered in the injector: a second `Dio()` created inside a data source
/// would silently miss the token, the timeouts and the logging, and would work perfectly right
/// up until the first authenticated call.
abstract final class DioClient {
  static Dio create({
    required TokenStorage tokens,
    required Session session,
    required Future<void> Function() onUnauthorized,
    required Future<void> Function() refreshSession,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // 4xx must reach the interceptors and `safeRequest` as a DioException carrying the
        // body — that body is where the API's Arabic message and field errors are.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        tokens,
        session,
        onUnauthorized: onUnauthorized,
        refreshSession: refreshSession,
      ),
    );

    // Never in release: request and response bodies contain customer data and the bearer
    // token, and `kReleaseMode` is the only check that cannot be forgotten by a flag.
    if (AppConfig.isDev && !kReleaseMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: true,
        ),
      );
    }

    return dio;
  }
}
