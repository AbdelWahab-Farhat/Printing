import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';

/// The headings, for the filter chips.
class ListCategories {
  const ListCategories(this._repository);

  final CatalogRepository _repository;

  Future<Either<Failure, List<ProductCategory>>> call() => _repository.categories();
}
