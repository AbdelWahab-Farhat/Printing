import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/repositories/product_repository.dart';

/// Fulfils [ProductRepository] over HTTP.
///
/// The list endpoint already returns each product's variants and their price breaks, so a
/// catalogue screen can show a starting price without a request per row. That is the server's
/// contract, not an assumption: see `ProductListQuery`.
class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Product>>> products({
    String? search,
    String? category,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Product>(
      () => _dio.get(
        ProductEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: Product.fromJson,
    );
  }

  @override
  Future<Either<Failure, Product>> product(int productId) {
    return safeRequest<Product>(
      () => _dio.get(ProductEndpoints.show(productId)),
      parse: (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }
}
