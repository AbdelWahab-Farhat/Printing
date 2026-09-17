import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';

class GetBadges {
  const GetBadges(this._repository);

  final BadgeRepository _repository;

  Future<Either<Failure, Map<CustomerBadge, int>>> call() => _repository.badges();
}
