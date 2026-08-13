import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository.dart';

/// Fulfils [ManufacturingCostRateRepository] over HTTP.
class ManufacturingCostRateRepositoryImpl implements ManufacturingCostRateRepository {
  const ManufacturingCostRateRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<ManufacturingCostRate>>> rates({
    int? productId,
    int? productVariantId,
    ManufacturingCostType? costType,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<ManufacturingCostRate>(
      () => _dio.get(
        ManufacturingCostRateEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          'product_id': ?productId,
          'product_variant_id': ?productVariantId,
          // [ManufacturingCostType.unknown] is dropped with the same care: its wire is the empty
          // string, and this filter is parsed with a bare `from()` on the server — a value the
          // enum cannot read comes back as a 500 «حدث خطأ ما», not as a 422 anybody could act on.
          if (costType != null && costType != ManufacturingCostType.unknown)
            'cost_type': costType.wire,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: ManufacturingCostRate.fromJson,
    );
  }

  @override
  Future<Either<Failure, ManufacturingCostRate>> rate(int rateId) {
    return safeRequest<ManufacturingCostRate>(
      () => _dio.get(ManufacturingCostRateEndpoints.show(rateId)),
      parse: (data) => ManufacturingCostRate.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ManufacturingCostRate>> create({
    required ManufacturingCostType costType,
    required String ratePerUnit,
    int? productId,
    int? productVariantId,
    String? notes,
    bool isActive = true,
  }) {
    return safeRequest<ManufacturingCostRate>(
      () => _dio.post(
        ManufacturingCostRateEndpoints.index,
        data: _body(
          costType: costType,
          ratePerUnit: ratePerUnit,
          productId: productId,
          productVariantId: productVariantId,
          notes: notes,
          isActive: isActive,
        ),
      ),
      parse: (data) => ManufacturingCostRate.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ManufacturingCostRate>> update(
    int rateId, {
    required ManufacturingCostType costType,
    required String ratePerUnit,
    int? productId,
    int? productVariantId,
    String? notes,
    bool isActive = true,
  }) {
    return safeRequest<ManufacturingCostRate>(
      () => _dio.put(
        ManufacturingCostRateEndpoints.show(rateId),
        data: _body(
          costType: costType,
          ratePerUnit: ratePerUnit,
          productId: productId,
          productVariantId: productVariantId,
          notes: notes,
          isActive: isActive,
        ),
      ),
      parse: (data) => ManufacturingCostRate.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ManufacturingCostRate>> setActivation(
    int rateId, {
    required bool isActive,
  }) {
    return safeRequest<ManufacturingCostRate>(
      () => _dio.patch(
        ManufacturingCostRateEndpoints.activation(rateId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => ManufacturingCostRate.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int rateId) {
    return safeCommand(() => _dio.delete(ManufacturingCostRateEndpoints.show(rateId)));
  }

  /// The whole record either way, and one helper so a field cannot be added to the create and
  /// forgotten on the update.
  ///
  /// **Every key travels, including the nulls.** The update is a full replacement: the server
  /// rebuilds the row from this body and defaults whatever is missing — an absent tier id
  /// silently demotes a product-wide rate to the default one, an absent `is_active` re-offers a
  /// rate somebody stopped, and absent notes erase them. Sending the nulls is what makes «امسح
  /// الملاحظة» mean that and nothing else.
  ///
  /// [productId] and [productVariantId] are never both set here, because they are never both
  /// set upstream — the form picks one rung and the use case puts one id on the wire.
  Map<String, dynamic> _body({
    required ManufacturingCostType costType,
    required String ratePerUnit,
    required int? productId,
    required int? productVariantId,
    required String? notes,
    required bool isActive,
  }) {
    return <String, dynamic>{
      'product_id': productId,
      'product_variant_id': productVariantId,
      'cost_type': costType.wire,
      // Sent as the text it was typed as: `numeric` accepts a decimal string, so nothing here
      // has to round-trip money through a float to satisfy the rule.
      'rate_per_unit': ratePerUnit,
      'is_active': isActive,
      'notes': notes,
    };
  }
}
