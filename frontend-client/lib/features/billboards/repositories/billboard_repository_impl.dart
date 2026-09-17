import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [BillboardRepository] over HTTP.
class BillboardRepositoryImpl implements BillboardRepository {
  const BillboardRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<Billboard>>> showing() {
    return safeRequest<List<Billboard>>(
      () => _dio.get(BillboardEndpoints.index),
      parse: (data) => (data as List<dynamic>)
          .map((item) => Billboard.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
