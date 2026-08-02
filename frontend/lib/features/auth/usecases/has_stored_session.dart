import 'package:printing/features/auth/repositories/auth_repository.dart';

/// Whether this device is carrying a token at all.
///
/// Synchronous, and that is the point: it is asked before the first frame, to decide whether
/// there is anything worth *checking* over the network. Spending a request to discover that
/// nobody has ever signed in on this phone is a second of splash screen for no answer.
///
/// It says nothing about whether the token still works — only [GetCurrentUser] can, and only by
/// asking the server.
class HasStoredSession {
  const HasStoredSession(this._repository);

  final AuthRepository _repository;

  bool call() => _repository.hasStoredToken;
}
