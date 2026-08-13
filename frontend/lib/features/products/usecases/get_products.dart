import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/repositories/product_repository.dart';

/// One page of the catalogue.
class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, Paginated<Product>>> call({
    String? search,
    String? category,
    int? productCategoryId,
    String? pricingUnit,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.products(
      // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
      // silently finds nothing, and every caller would otherwise have to remember this.
      search: search?.trim(),
      category: category,
      productCategoryId: productCategoryId,
      pricingUnit: pricingUnit,
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
