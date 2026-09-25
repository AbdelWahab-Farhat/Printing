import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';

/// Where an order can be sent.
abstract interface class DeliveryRepository {
  /// Every destination, each with its neighbourhoods, in the order the business keeps them.
  ///
  /// **One call for the whole map.** The list is a country's worth of places; it is fetched
  /// once and held, rather than paged behind a picker somebody scrolls off the end of.
  Future<Either<Failure, List<City>>> cities();
}
