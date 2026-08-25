import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dio/dio.dart';

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
    int? productCategoryId,
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
          // Omitted rather than sent empty: the API reads a blank as «كل التصنيفات», and this
          // keeps the query string honest about what was actually asked.
          'product_category_id': ?productCategoryId,
          if (pricingUnit != null && pricingUnit.isNotEmpty)
            'pricing_unit': pricingUnit,
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
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  }) {
    return safeRequest<PriceQuote>(
      // The quantity goes as the string it is. Sending it as a number would hand it to
      // `jsonEncode` as a double, and `300.5` is the least of what that can do to a decimal.
      () => _dio.post(
        ProductEndpoints.quote(productId),
        data: <String, dynamic>{'variant_id': variantId, 'quantity': quantity},
      ),
      parse: (data) => PriceQuote.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Product>> create(
    NewProduct product, {
    required PickedFile image,
  }) {
    return safeRequest<Product>(
      // **`multipart/form-data`, unlike every other write in this class.** The server requires a
      // photo to create a product, so the picture and the fields have to arrive together.
      //
      // `FormData.fromMap` flattens the nesting for us — `variants[0][price_tiers][0][unit_price]`
      // — which is why the body is still built by `toJson` rather than assembled by hand here.
      //
      // `fromFile` streams from disk rather than reading the picture into memory first.
      () async => _dio.post(
        ProductEndpoints.index,
        data: FormData.fromMap(<String, dynamic>{
          ...product.toJson(),
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        }),
      ),
      parse: (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Product>> update(int productId, NewProduct product) {
    return safeRequest<Product>(
      // `toJson()` and nothing added here, which is what keeps the trap survivable: the whole
      // variant set is replaced by this call and every size's shelf re-resolved from what is in
      // the body, so the round-trip has to be built into the model rather than patched in at the
      // last moment by whoever remembered. See `NewProductVariant.stockItemId`.
      () => _dio.put(ProductEndpoints.show(productId), data: product.toJson()),
      parse: (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProductImage>> uploadImage(
    int productId, {
    required PickedFile image,
    void Function(int sent, int total)? onProgress,
  }) {
    return safeRequest<ProductImage>(
      // `fromFile` streams from disk. `fromBytes` would hold the whole picture in memory for the
      // length of the upload, which a mid-range phone kills the app for.
      () async => _dio.post(
        ProductEndpoints.images(productId),
        data: FormData.fromMap(<String, dynamic>{
          'image': await MultipartFile.fromFile(image.path, filename: image.name),
        }),
        onSendProgress: onProgress,
      ),
      parse: (data) => ProductImage.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProductImage>> makeImagePrimary(int productId, int imageId) {
    return safeRequest<ProductImage>(
      // `true` and nothing else: the rule is `accepted`, so `false` is a validation error rather
      // than a demotion. Sending the flag at all is what this call means.
      () => _dio.patch(
        ProductEndpoints.image(productId, imageId),
        data: <String, dynamic>{'is_primary': true},
      ),
      parse: (data) => ProductImage.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> deleteImage(int productId, int imageId) {
    // `safeCommand`, because the answer is a message rather than a record — and the message is
    // the server's own Arabic when it refuses, which is what the screen shows for the one
    // refusal that matters: the last photograph.
    return safeCommand(() => _dio.delete(ProductEndpoints.image(productId, imageId)));
  }
}
