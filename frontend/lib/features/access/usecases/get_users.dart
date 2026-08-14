import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// One page of staff accounts.
class GetUsers {
  const GetUsers(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, Paginated<AuthUser>>> call({
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.users(search: search, page: page, perPage: perPage);
  }
}
