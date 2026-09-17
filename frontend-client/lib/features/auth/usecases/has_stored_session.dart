import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';

/// Whether this device is holding a token at all.
///
/// Synchronous and cheap, because the router's guard cannot await: it decides where to send
/// somebody before any request is made. Whether the token is still *good* is
/// `GetCurrentCustomer`'s question, asked once the screen is up.
class HasStoredSession {
  const HasStoredSession(this._repository);

  final AuthRepository _repository;

  bool call() => _repository.hasStoredToken;
}
