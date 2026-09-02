import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [ProductCategoryRepository] over HTTP.
class ProductCategoryRepositoryImpl implements ProductCategoryRepository {
  const ProductCategoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<ProductCategory>>> categories({
    String? search,
    bool? isActive,
    bool leafOnly = false,
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
          // Sent only when it is being asked for: `leaf_only=0` and no key at all mean the same
          // thing to the API, and the shorter query string is the honest one.
          if (leafOnly) 'leaf_only': 1,
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
    required bool skipsProduction,
  }) {
    return safeRequest<ProductCategory>(
      () => _dio.post(
        ProductCategoryEndpoints.index,
        data: <String, dynamic>{
          'name': name,
          'sort_order': sortOrder,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          // Always sent, false included. The API defaults it to false when the key is absent,
          // so omitting it would agree with the server today and hide the day it stops — and a
          // POST that carries every answer the form collected is the one a log can be read from.
          'skips_production': skipsProduction,
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
    required bool skipsProduction,
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
          // A PUT replaces the whole representation, so leaving this out would take the flag
          // off every heading that had it on the next rename — the same trap `is_active` is
          // spelled out for above.
          'skips_production': skipsProduction,
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
  Future<Either<Failure, String>> reorder(List<int> orderedIds) {
    // A command: the answer is the server's message, because the list is re-read from the API
    // afterwards rather than patched from a response.
    return safeCommand(
      () => _dio.patch(
        ProductCategoryEndpoints.order,
        data: <String, dynamic>{'ids': orderedIds},
      ),
    );
  }

  @override
  Future<Either<Failure, ProductCategory>> setImage(
    int categoryId, {
    required String path,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) {
    return safeRequest<ProductCategory>(
      () async => _dio.post(
        ProductCategoryEndpoints.image(categoryId),
        // `fromFile` streams from disk. `fromBytes` would hold the whole picture in memory for
        // the length of the upload, which a mid-range phone kills the app for.
        data: FormData.fromMap(<String, dynamic>{
          'image': await MultipartFile.fromFile(path, filename: filename),
        }),
        onSendProgress: onProgress,
      ),
      parse: (data) => ProductCategory.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProductCategory>> removeImage(int categoryId) {
    return safeRequest<ProductCategory>(
      () => _dio.delete(ProductCategoryEndpoints.image(categoryId)),
      parse: (data) => ProductCategory.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int categoryId) {
    return safeCommand(() => _dio.delete(ProductCategoryEndpoints.show(categoryId)));
  }
}
