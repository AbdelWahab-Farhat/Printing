import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dio/dio.dart';

class OnlinePaymentRepositoryImpl implements OnlinePaymentRepository {
  const OnlinePaymentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<PaymentIntent>>> intents({
    required int page,
    IntentFilter filter = IntentFilter.all,
    String? search,
  }) {
    return safePaginatedRequest<PaymentIntent>(
      () => _dio.get(
        OnlinePaymentEndpoints.intents,
        // المفاتيح الفارغة تُحذف ولا تُرسل — RULES §٦.
        queryParameters: {'page': page, 'status': ?filter.wire, 'q': ?search},
      ),
      parseItem: PaymentIntent.fromJson,
    );
  }

  @override
  Future<Either<Failure, PaymentIntent>> recheck(String uuid) {
    return safeRequest<PaymentIntent>(
      () => _dio.post(OnlinePaymentEndpoints.recheck(uuid)),
      parse: (data) => PaymentIntent.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, OnlinePaymentMethods>> methods() {
    return safeRequest<OnlinePaymentMethods>(
      () => _dio.get(OnlinePaymentEndpoints.methods),
      parse: (data) => OnlinePaymentMethods.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, OnlinePaymentMethodSetting>> updateMethod(
    int id, {
    bool? isActive,
    Map<String, String?>? limits,
  }) {
    return safeRequest<OnlinePaymentMethodSetting>(
      () => _dio.patch(
        OnlinePaymentEndpoints.method(id),
        // الحدُّ الفارغ يُرسل `null` عن قصد: «بلا حد».
        data: <String, dynamic>{'is_active': ?isActive, ...?limits},
      ),
      parse: (data) => OnlinePaymentMethodSetting.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, EzonePayout>> recordPayout({
    required String amount,
    String? kept,
    int? toAccountId,
    String? reference,
    required String clientToken,
  }) {
    return safeRequest<EzonePayout>(
      () => _dio.post(
        OnlinePaymentEndpoints.payouts,
        data: <String, dynamic>{
          'amount': amount,
          'kept': ?kept,
          'to_account_id': ?toAccountId,
          if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
          'client_token': clientToken,
        },
      ),
      parse: (data) => EzonePayout.fromJson(data as Map<String, dynamic>),
    );
  }
}
