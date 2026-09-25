import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';

/// The destination picker's contents.
class ListCities {
  const ListCities(this._repository);

  final DeliveryRepository _repository;

  Future<Either<Failure, List<City>>> call() => _repository.cities();
}
