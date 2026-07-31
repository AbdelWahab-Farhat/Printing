import 'package:dio/dio.dart';
import 'package:printing/core/storage/token_storage.dart';

/// Attaches the bearer token, and reacts to the server saying it is no longer good.
///
/// Both halves live here rather than in a base repository: forgetting the header on one call
/// is a 401 nobody can explain, and handling "session expired" in each Cubit would give the
/// user a different experience depending on which screen happened to notice first.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, {required this.onUnauthorized});

  final TokenStorage _tokens;

  /// Called once the server has rejected the token. The app listens and sends the user to
  /// login — this class does not know what a route is.
  final Future<void> Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // 403 is deliberately *not* here: it means "you are signed in but may not do this", and
    // logging someone out for opening a screen they lack a permission for is a bug that
    // feels like a crash.
    if (err.response?.statusCode == 401) {
      await _tokens.clear();
      await onUnauthorized();
    }

    handler.next(err);
  }
}
