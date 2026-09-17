import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';

/// One product, with its sizes and price breaks.
class GetProduct {
  const GetProduct(this._repository);

  final CatalogRepository _repository;

  Future<Either<Failure, Product>> call(int id) => _repository.product(id);
}
