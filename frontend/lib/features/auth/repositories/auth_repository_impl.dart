import 'dart:io' show Platform;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/storage/token_storage.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fulfils [AuthRepository] over HTTP, and owns where the token is kept.
///
/// The Dio calls live here rather than in a separate data source. With one source of data, the
/// extra class only forwarded — a second file to open on the way to the request. If a local
/// cache ever lands beside the network, *that* is when the split earns its place, and the
/// contract above means nothing else has to change when it does.
///
/// Storing the token here rather than in the Cubit is deliberate: persistence is a data
/// concern, and if the ViewModel had to remember to save it, the one screen that forgot would
/// produce a session that works until the app restarts and then mysteriously does not.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio, this._tokens, this._session);

  final Dio _dio;
  final TokenStorage _tokens;

  /// Identity has the same shape as persistence: if a ViewModel had to remember to adopt the
  /// user, the one screen that forgot would leave every gated control hidden with no clue why.
  /// So it happens here, beside the token, and only here.
  final Session _session;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  }) async {
    final result = await safeRequest<AuthSession>(
      () => _dio.post(
        AuthEndpoints.login,
        data: <String, dynamic>{
          // The API's field is `login` and takes an email *or* a phone. The app only ever
          // collects a phone, and that translation stops right here — nothing above this line
          // needs to know the field is called something else.
          'login': phone,
          'password': password,

          // Names the token so a person can see their devices and revoke one of them.
          'device_name': _deviceName(),
        },
      ),
      parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );

    // Both branches are async on purpose: mixing a sync one with an async one makes `fold`
    // infer a useless common supertype instead of Future<Either<…>>.
    return result.fold(
      (failure) async => Left(failure),
      (session) async {
        // Written before returning, so the next request is authenticated without the caller
        // having to sequence anything.
        await _tokens.write(session.token);
        _session.adopt(session.user);

        return Right(session);
      },
    );
  }

  @override
  Future<Either<Failure, AuthUser>> currentUser() async {
    final result = await safeRequest<AuthUser>(
      () => _dio.get(AuthEndpoints.me),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );

    return result.fold(
      (failure) async {
        // The server has disowned this token, so keeping it would send the user in a loop:
        // start-up trusts it, the first request 401s, and they land back here.
        if (failure is UnauthorizedFailure) {
          await _tokens.clear();
          _session.clear();
        }

        return Left(failure);
      },
      (user) async {
        // Inside the call the splash awaits, so the set is filled before the first gated
        // widget can exist. Do not move this up into the ViewModel.
        _session.adopt(user);

        return Right(user);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final result = await safeCommand(() => _dio.post(AuthEndpoints.logout));

    // Cleared whatever the server said. If the request failed because the device is offline,
    // the person still asked to sign out and must not be left signed in — the worst case is a
    // token that stays valid server-side until it expires, which is far better than a shared
    // phone that never logs out.
    await _tokens.clear();
    _session.clear();

    return result.map((_) => unit);
  }

  @override
  bool get hasStoredToken => _tokens.hasTokenInMemory;

  /// A label for the token, not an identifier — it only has to be readable in a device list.
  String _deviceName() {
    if (kIsWeb) return 'web';

    return Platform.operatingSystem;
  }
}
