import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';

/// Check the stored token against the server and read back who it belongs to.
///
/// **This is how a token is checked rather than trusted.** It may have been revoked from
/// another device since it was saved, and a start-up that believed it would send the customer
/// into a loop: trust, 401, back to login, holding the same dead token.
class GetCurrentCustomer {
  const GetCurrentCustomer(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, CustomerAccount>> call() => _repository.currentCustomer();
}
