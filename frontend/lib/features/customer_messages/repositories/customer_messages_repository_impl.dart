import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';
import 'package:dayaa/features/customer_messages/repositories/customer_messages_repository.dart';
import 'package:dio/dio.dart';

class CustomerMessagesRepositoryImpl implements CustomerMessagesRepository {
  const CustomerMessagesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, CustomerMessages>> messages() {
    return safeRequest<CustomerMessages>(
      () => _dio.get(SettingsEndpoints.customerMessages),
      parse: (data) => CustomerMessages.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CustomerMessages>> update(Map<String, String?> bodies) {
    return safeRequest<CustomerMessages>(
      () => _dio.put(
        SettingsEndpoints.customerMessages,
        data: <String, dynamic>{'messages': bodies},
      ),
      parse: (data) => CustomerMessages.fromJson(data as Map<String, dynamic>),
    );
  }
}
