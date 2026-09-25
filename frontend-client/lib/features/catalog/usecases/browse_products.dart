import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';

/// One page of the catalogue, optionally searched or narrowed to a heading.
class BrowseProducts {
  const BrowseProducts(this._repository);

  final CatalogRepository _repository;

  Future<Either<Failure, Paginated<Product>>> call({
    int page = 1,
    String? search,
    int? categoryId,
  }) => _repository.products(page: page, search: search, categoryId: categoryId);
}
