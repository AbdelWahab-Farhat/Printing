import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';

/// What is waiting for the signed-in customer.
abstract interface class BadgeRepository {
  /// Every badge the server knows, with its current count.
  ///
  /// **Asked as one call.** Several tiles asking separately would be several round trips on
  /// every launch, on the connection where the round trip is the expensive part.
  Future<Either<Failure, Map<CustomerBadge, int>>> badges();
}
