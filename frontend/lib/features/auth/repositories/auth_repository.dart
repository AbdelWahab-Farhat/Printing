import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// What the app can do about a session, stated without saying how.
///
/// The abstraction stays even though the entity layer went, and for one concrete reason: the
/// Cubit depends on *this*, so a test hands it a fake in a line and never constructs Dio or
/// touches the Keychain. That is the part of the layering that pays for itself; the rest was
/// ceremony.
abstract interface class AuthRepository {
  /// Signs in with a phone number and password.
  ///
  /// The API's field is `login` and accepts an email *or* a phone; this app only ever collects
  /// a phone, and that translation stops in the implementation.
  ///
  /// On success the token is persisted before returning, so the very next request is
  /// authenticated without the caller having to remember to store it.
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  });

  /// Re-reads the signed-in account from the server using the stored token.
  ///
  /// This is how a stored token is *checked* rather than trusted: it may have been revoked
  /// from another device since it was saved. Returns [UnauthorizedFailure] when it is no
  /// longer good.
  Future<Either<Failure, AuthUser>> currentUser();

  /// Ends this device's session. The token is cleared locally even if the call fails —
  /// see the implementation for why.
  Future<Either<Failure, Unit>> logout();

  /// Whether a token was found on this device. Cheap and synchronous — used to decide where
  /// to send someone at start-up before any request is made.
  bool get hasStoredToken;
}
