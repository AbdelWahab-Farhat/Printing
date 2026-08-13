import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';

/// Fulfils [ProductCategoryRepository] over HTTP.
class ProductCategoryRepositoryImpl implements ProductCategoryRepository {
  const ProductCategoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<ProductCategory>>> categories({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<ProductCategory>(
      () => _dio.get(
        ProductCategoryEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: ProductCategory.fromJson,
    );
  }

  @override
  Future<Either<Failure, ProductCategory>> create({
    required String name,
    String? description,
    required int sortOrder,
  }) {
    return safeRequest<ProductCategory>(
      () => _dio.post(
        ProductCategoryEndpoints.index,
        data: <String, dynamic>{
          'name': name,
          'sort_order': sortOrder,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      ),
      parse: (data) => ProductCategory.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProductCategory>> update(
    int categoryId, {
    required String name,
    String? description,
    required int sortOrder,
    required bool isActive,
  }) {
    return safeRequest<ProductCategory>(
      // A PUT sends the category's whole representation, which is why `is_active` is here and
      // not only on the activation endpoint: leaving it out of a full replacement would
      // silently re-offer a stopped category on every rename.
      //
      // `description` is always present, null included: a description somebody cleared must
      // arrive as null to be cleared, which an "omit when empty" would prevent forever.
      () => _dio.put(
        ProductCategoryEndpoints.show(categoryId),
        data: <String, dynamic>{
          'name': name,
          'description': (description?.trim().isEmpty ?? true) ? null : description!.trim(),
          'sort_order': sortOrder,
          'is_active': isActive,
        },
      ),
      parse: (data) => ProductCategory.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProductCategory>> setActivation(
    int categoryId, {
    required bool isActive,
  }) {
    return safeRequest<ProductCategory>(
      () => _dio.patch(
        ProductCategoryEndpoints.activation(categoryId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => ProductCategory.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int categoryId) {
    return safeCommand(() => _dio.delete(ProductCategoryEndpoints.show(categoryId)));
  }
}
