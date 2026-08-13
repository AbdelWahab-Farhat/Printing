import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product_category.dart';

/// Reading and curating التصنيفات, stated without saying how.
abstract interface class ProductCategoryRepository {
  /// One page of categories, in the catalogue's own order.
  ///
  /// [isActive] left null returns both the offered and the stopped ones — which is what the
  /// management screen wants. A picker asks for `true`.
  Future<Either<Failure, Paginated<ProductCategory>>> categories({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, ProductCategory>> create({
    required String name,
    String? description,
    required int sortOrder,
  });

  Future<Either<Failure, ProductCategory>> update(
    int categoryId, {
    required String name,
    String? description,
    required int sortOrder,
    required bool isActive,
  });

  /// Hides a category from the pickers. The products already under it keep it.
  Future<Either<Failure, ProductCategory>> setActivation(
    int categoryId, {
    required bool isActive,
  });

  /// Only for a row that should never have existed. The server refuses with 422 once any
  /// product points at the category — deactivation is what retires one in use. Answers with the
  /// server's own message, so the screen says what happened in the words the API chose.
  Future<Either<Failure, String>> delete(int categoryId);
}
