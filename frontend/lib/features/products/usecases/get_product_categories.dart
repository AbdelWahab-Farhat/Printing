import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';

/// One page of التصنيفات.
class GetProductCategories {
  const GetProductCategories(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, Paginated<ProductCategory>>> call({
    String? search,
    bool? isActive,
    bool leafOnly = false,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.categories(
      // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
      // silently finds nothing, and every caller would otherwise have to remember this.
      search: search?.trim(),
      isActive: isActive,
      leafOnly: leafOnly,
      page: page,
      perPage: perPage,
    );
  }
}
