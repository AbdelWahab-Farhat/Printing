import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/domain/entities/city.dart';

/// What the app can ask about the delivery map, stated without saying how.
///
/// The contract lives in `domain/` and its implementation in `data/` — that inversion is the
/// point of the layer. The Cubit depends on this, so a test hands it a fake in one line and
/// never touches Dio, and adding an offline cache later is a change to the implementation with
/// nothing above it to update.
abstract interface class CityRepository {
  Future<Either<Failure, Paginated<City>>> cities({
    String? search,
    bool? isRegionRequired,
    bool? hasPrice,
    int page,
    int perPage,
  });

  Future<Either<Failure, City>> city(int cityId);

  Future<Either<Failure, Paginated<Region>>> regions(
    int cityId, {
    String? search,
    int page,
    int perPage,
  });
}
