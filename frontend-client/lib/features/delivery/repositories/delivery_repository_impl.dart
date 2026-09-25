import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [DeliveryRepository] over HTTP.
class DeliveryRepositoryImpl implements DeliveryRepository {
  const DeliveryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<City>>> cities() {
    return safeRequest<List<City>>(
      () => _dio.get(DeliveryEndpoints.cities),
      parse: (data) => (data as List<dynamic>)
          .map((item) => City.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
