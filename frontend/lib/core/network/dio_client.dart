import 'package:dayaa/core/config/app_config.dart';
import 'package:dayaa/core/network/auth_interceptor.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        // 4xx must reach the interceptors and `safeRequest` as a DioException carrying the
        // body — that body is where the API's Arabic message and field errors are.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        /*
         * **`status[]=a&status[]=b`, not `status=a&status=b`.** Dio's default is the second,
         * and PHP throws all but the last value away — so a filter for four statuses reached
         * the API as a filter for *one*, and the list came back narrowed to whichever happened
         * to be sent last.
         *
         * That is not a hypothetical. It was caught while the orders filter still offered
         * *groups*: «رواجع» stood for four statuses ending in `resend`, so the row counted four
         * orders and showed none of them, and «قيد التنفيذ» was wrong more quietly — it showed
         * the printing orders and silently dropped the ones being designed. The filter names
         * single statuses now, but `payment_status` is still ticked several at a time and the
         * API still takes a list, so the format is what keeps both honest.
         *
         * Set on the shared client rather than per request, because every repeatable filter
         * this API has needs it and the next one will be written by somebody who never met
         * this bug. `orders_query_format_test.dart` pins the shape.
         */
        listFormat: ListFormat.multiCompatible,
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
