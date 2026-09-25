import 'dart:io' show Platform;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fulfils [AuthRepository] over HTTP, and owns where the token is kept.
///
/// **Shorter than the staff app's by three dependencies, and each absence is a decision recorded
/// in BACKLOG.md.** There is no `Session` to adopt the account into, because a customer holds no
/// permissions for anything to read. There is no `PushService` to register or release, because
/// what a customer should be notified about — and the Firebase project that would carry it — is
/// still open. There is no `SettingsRepository` for the same reason. When push lands, the
/// release call belongs in [logout] *before* the request, exactly as it does there: releasing a
/// device is itself an authenticated call, and after the token is cleared it would 401.
///
/// Storing the token here rather than in the Cubit is deliberate: persistence is a data concern,
/// and if the ViewModel had to remember to save it, the one screen that forgot would produce a
/// session that works until the app restarts and then mysteriously does not.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final result = await safeRequest<AuthSession>(
      () => _dio.post(
        AuthEndpoints.register,
        data: <String, dynamic>{
          'name': name,
          'phone': phone,
          'password': password,
          // The server asks for it confirmed. The same value is sent rather than a second field
          // being carried down here: the screen already compares the two before it calls, and a
          // mismatch should be a message beside the field rather than a round trip.
          'password_confirmation': password,
          'device_name': _deviceName(),
        },
      ),
      parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );

    return _persist(result);
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  }) async {
    final result = await safeRequest<AuthSession>(
      () => _dio.post(
        AuthEndpoints.login,
        data: <String, dynamic>{
          // The field is `phone`, not `login`. The staff endpoint accepts an email *or* a phone
          // and so calls its field `login`; a customer account has only ever had one
          // identifier, so the customer endpoint names it plainly and no translation is needed.
          'phone': phone,
          'password': password,

          // Names the token so a person can see their devices and revoke one of them.
          'device_name': _deviceName(),
        },
      ),
      parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );

    return _persist(result);
  }

  @override
  Future<Either<Failure, CustomerAccount>> currentCustomer() async {
    final result = await safeRequest<CustomerAccount>(
      () => _dio.get(AuthEndpoints.me),
      parse: (data) => CustomerAccount.fromJson(data as Map<String, dynamic>),
    );

    return result.fold(
      (failure) async {
        // The server has disowned this token, so keeping it would send the customer in a loop:
        // start-up trusts it, the first request 401s, and they land back at the login screen
        // still holding the dead token.
        if (failure is UnauthorizedFailure) await _tokens.clear();

        return Left(failure);
      },
      (customer) async => Right(customer),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final result = await safeCommand(() => _dio.post(AuthEndpoints.logout));

    // Cleared whatever the server said. If the request failed because the phone is offline, the
    // person still asked to sign out and must not be left signed in — the worst case is a token
    // that stays valid server-side until it expires, which is far better than a shared phone
    // that never logs out.
    await _tokens.clear();

    return result.map((_) => unit);
  }

  @override
  bool get hasStoredToken => _tokens.hasTokenInMemory;

  /// Writes the token before handing the session back, so the next request is authenticated
  /// without the caller having to sequence anything.
  ///
  /// Both branches are async on purpose: mixing a sync one with an async one makes `fold` infer
  /// a useless common supertype instead of `Future<Either<…>>`.
  Future<Either<Failure, AuthSession>> _persist(
    Either<Failure, AuthSession> result,
  ) async {
    return result.fold(
      (failure) async => Left(failure),
      (session) async {
        await _tokens.write(session.token);

        return Right(session);
      },
    );
  }

  /// A label for the token, not an identifier — it only has to be readable in a device list.
  String _deviceName() {
    if (kIsWeb) return 'web';

    return Platform.operatingSystem;
  }
}
