import 'dart:async';

import 'package:dio/dio.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/storage/token_storage.dart';

/// Attaches the bearer token, and reacts to the server saying it is no longer good.
///
/// Both halves live here rather than in a base repository: forgetting the header on one call
/// is a 401 nobody can explain, and handling "session expired" in each Cubit would give the
/// user a different experience depending on which screen happened to notice first.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, this._session, {
    required this.onUnauthorized,
    required this.refreshSession,
  });

  final TokenStorage _tokens;

  /// Cleared here rather than left to [onUnauthorized]: the token and the permission set are
  /// the two halves of "you are signed in", and splitting their clearing across two files is
  /// how one of them gets forgotten.
  final Session _session;

  /// Re-reads `/auth/me`. Injected as a callback because an interceptor must not import a
  /// repository — that dependency would point the wrong way.
  final Future<void> Function() refreshSession;

  bool _isRefreshing = false;

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
    if (err.response?.statusCode == 401) {
      await _tokens.clear();
      _session.clear();
      await onUnauthorized();
    }

    // 403 never signs anyone out: it means "you are signed in but may not do this", and
    // logging someone out for opening a screen they lack a permission for is a bug that feels
    // like a crash.
    //
    // It does mean our copy of the permissions is stale, though — the app offered something the
    // server refused. Re-read them so the *next* screen is right, even though this one was not.
    // Unawaited: the caller's failure is already on its way up and must not wait behind this.
    // The flag collapses a burst of parallel 403s into one request rather than one per widget,
    // and it cannot loop — `/auth/me` sits behind authentication only and can never 403.
    if (err.response?.statusCode == 403 && !_isRefreshing) {
      _isRefreshing = true;
      unawaited(refreshSession().whenComplete(() => _isRefreshing = false));
    }

    handler.next(err);
  }
}
