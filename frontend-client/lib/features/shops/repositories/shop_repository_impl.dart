import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [ShopRepository] over HTTP.
class ShopRepositoryImpl implements ShopRepository {
  const ShopRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<Shop>>> list() {
    return safeRequest<List<Shop>>(
      () => _dio.get(ShopEndpoints.index),
      parse: (data) => (data as List<dynamic>)
          .map((item) => Shop.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, Shop>> add({
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  }) {
    return safeRequest<Shop>(
      () => _dio.post(
        ShopEndpoints.store,
        data: _body(
          name: name,
          cityId: cityId,
          regionId: regionId,
          businessFieldId: businessFieldId,
          pageUrl: pageUrl,
        ),
      ),
      parse: (data) => Shop.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shop>> update({
    required int id,
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  }) {
    return safeRequest<Shop>(
      () => _dio.put(
        ShopEndpoints.shop(id),
        data: _body(
          name: name,
          cityId: cityId,
          regionId: regionId,
          businessFieldId: businessFieldId,
          pageUrl: pageUrl,
        ),
      ),
      parse: (data) => Shop.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> remove(int id) async {
    final result = await safeCommand(() => _dio.delete(ShopEndpoints.shop(id)));

    return result.map((_) => unit);
  }

  @override
  Future<Either<Failure, List<BusinessField>>> businessFields() {
    return safeRequest<List<BusinessField>>(
      () => _dio.get(ShopEndpoints.businessFields),
      parse: (data) => (data as List<dynamic>)
          .map((item) => BusinessField.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// **الحقول الاختيارية تُرسل `null` صراحةً ولا تُحذف.** التعديل يرسل المتجر كاملاً، ومنطقةٌ أو مجالٌ
  /// أو رابطٌ مُسح في النموذج يجب أن يُمسح على الخادم أيضاً — والمفتاح الغائب كان سيُقرأ «مُسح»
  /// بالمصادفة لا بالقصد.
  Map<String, dynamic> _body({
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  }) => <String, dynamic>{
    'name': name,
    'business_field_id': businessFieldId,
    'city_id': cityId,
    'region_id': regionId,
    'page_url': pageUrl,
  };
}
