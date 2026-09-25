import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';

/// What the app can do about a session, stated without saying how.
///
/// The abstraction stays although there is one implementation, for the reason the staff app
/// keeps it: the Cubit depends on *this*, so a test hands it a fake in a line and never
/// constructs Dio or touches the Keychain.
abstract interface class AuthRepository {
  /// Creates an account and returns a usable session.
  ///
  /// **No email.** A customer account has none — that absence is the reason these accounts do
  /// not live in the `users` table, whose email column is required and unique.
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String phone,
    required String password,
  });

  /// Signs in with a phone number and password.
  ///
  /// The staff app translates «phone» into the API's `login` field, which takes an email or a
  /// phone. There is no such translation here: the customer endpoint's field *is* `phone`,
  /// because a phone is the only identifier one of these accounts has.
  ///
  /// On success the token is persisted before returning, so the very next request is
  /// authenticated without the caller having to remember to store it.
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  });

  /// Re-reads the signed-in account from the server using the stored token.
  ///
  /// This is how a stored token is *checked* rather than trusted: it may have been revoked from
  /// another device since it was saved. Returns [UnauthorizedFailure] when it is no longer good.
  Future<Either<Failure, CustomerAccount>> currentCustomer();

  /// Ends this device's session. The token is cleared locally even if the call fails — see the
  /// implementation for why.
  Future<Either<Failure, Unit>> logout();

  /// Whether a token was found on this device. Cheap and synchronous — used to decide where to
  /// send somebody at start-up, before any request is made.
  bool get hasStoredToken;
}
