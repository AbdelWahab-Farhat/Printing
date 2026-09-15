import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Attaches the bearer token, and reacts to the server saying it is no longer good.
///
/// Both halves live here rather than in a base repository: forgetting the header on one call
/// is a 401 nobody can explain, and handling "session expired" in each Cubit would give the
/// user a different experience depending on which screen happened to notice first.
///
/// > **No 403 branch, unlike the staff app.** Over there a 403 triggers a silent re-read of
/// > `/auth/me`, because the app keeps a permission set that the refusal proves stale. A
/// > customer's account carries no permission set — what he may reach is his own records — so
/// > here a 403 is simply a failure travelling up to the Cubit that asked. The day this app
/// > holds per-account abilities, that branch comes back with them.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, {required this.onUnauthorized});

  final TokenStorage _tokens;

  /// Called once the server has rejected the token. The app listens and sends the user to
  /// login — this class does not know what a route is.
  final Future<void> Function() onUnauthorized;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.read();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokens.clear();
      await onUnauthorized();
    }

    handler.next(err);
  }
}
