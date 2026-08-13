import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';

/// One page of التصنيفات.
class GetProductCategories {
  const GetProductCategories(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, Paginated<ProductCategory>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.categories(
      // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
      // silently finds nothing, and every caller would otherwise have to remember this.
      search: search?.trim(),
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
