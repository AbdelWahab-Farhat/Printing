import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [CarrierRepository] over HTTP.
class CarrierRepositoryImpl implements CarrierRepository {
  const CarrierRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, NawrisParcel>> lodge(int orderId) {
    return safeRequest<NawrisParcel>(
      () => _dio.post(CarrierEndpoints.lodge(orderId)),
      parse: (data) => NawrisParcel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, NawrisParcel?>> resend(int orderId) =>
      _letGo(CarrierEndpoints.resend(orderId));

  @override
  Future<Either<Failure, NawrisParcel?>> deleteShipment(int orderId) =>
      _letGo(CarrierEndpoints.deleteShipment(orderId));

  @override
  Future<Either<Failure, NawrisParcel?>> unlink(int orderId) =>
      _letGo(CarrierEndpoints.unlink(orderId));

  /// The three that answer with a parcel **or** with nothing.
  ///
  /// An order with no open parcel comes back as a success carrying `data: null` — «لا توجد شحنة
  /// مفتوحة» — so a parser that insisted on a map would turn the server's polite answer into a
  /// crash. Re-sending shares the shape even though it *creates* rather than releases: the same
  /// "nothing out" answer applies, and the parcel it hands back is a new one either way.
  Future<Either<Failure, NawrisParcel?>> _letGo(String endpoint) {
    return safeRequest<NawrisParcel?>(
      () => _dio.post(endpoint),
      parse: (data) => data == null
          ? null
          : NawrisParcel.fromJson(data as Map<String, dynamic>),
    );
  }
}
