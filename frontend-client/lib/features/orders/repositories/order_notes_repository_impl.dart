import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/repositories/order_notes_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [OrderNotesRepository] over HTTP.
class OrderNotesRepositoryImpl implements OrderNotesRepository {
  const OrderNotesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<OrderNote>>> notes(int orderId) {
    return safeRequest<List<OrderNote>>(
      () => _dio.get(OrderEndpoints.notes(orderId)),
      parse: (data) => (data as List<dynamic>)
          .map((item) => OrderNote.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
