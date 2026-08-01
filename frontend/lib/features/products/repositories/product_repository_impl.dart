import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/products/models/new_product.dart';
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
    String? pricingUnit,
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
          if (pricingUnit != null && pricingUnit.isNotEmpty) 'pricing_unit': pricingUnit,
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

  @override
  Future<Either<Failure, Product>> create(NewProduct product) {
    return safeRequest<Product>(
      // `toJson` and not a Map literal assembled here: the body nests variants inside a product
      // and price tiers inside those, and a forty-line literal reachable only through Dio is a
      // shape no test can reach. As a model it is a pure function.
      () => _dio.post(ProductEndpoints.index, data: product.toJson()),
      parse: (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }
}
