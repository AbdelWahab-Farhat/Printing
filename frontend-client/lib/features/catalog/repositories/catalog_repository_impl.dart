import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [CatalogRepository] over HTTP.
class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Product>>> products({
    int page = 1,
    String? search,
    int? categoryId,
  }) {
    return safePaginatedRequest<Product>(
      () => _dio.get(
        CatalogEndpoints.products,
        queryParameters: <String, dynamic>{
          'page': page,
          // Omitted rather than sent empty: `?search=` is a filter the server would have to
          // decide the meaning of, and «كل المنتجات» is the absence of the key.
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'product_category_id': ?categoryId,
        },
      ),
      parseItem: Product.fromJson,
    );
  }

  @override
  Future<Either<Failure, Product>> product(int id) {
    return safeRequest<Product>(
      () => _dio.get(CatalogEndpoints.product(id)),
      parse: (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<ProductCategory>>> categories() {
    return safeRequest<List<ProductCategory>>(
      () => _dio.get(CatalogEndpoints.categories),
      parse: (data) => (data as List<dynamic>)
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  }) {
    return safeRequest<PriceQuote>(
      () => _dio.post(
        CatalogEndpoints.quote(productId),
        data: <String, dynamic>{
          'variant_id': variantId,
          // Sent as the string the screen collected. Parsing it to a double here and letting
          // Dio re-encode it is how `1000` becomes `1000.0` and a per-kilo quantity loses a
          // decimal place on the way out.
          'quantity': quantity,
        },
      ),
      parse: (data) => PriceQuote.fromJson(data as Map<String, dynamic>),
    );
  }
}
