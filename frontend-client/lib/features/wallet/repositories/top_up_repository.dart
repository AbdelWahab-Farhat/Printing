import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dio/dio.dart';

/// «اشحن محفظتك» عبر EzonePay — CUSTOMER-WALLET §٥. لا رقم عميل في شيءٍ هنا: المحفظة محفظةُ صاحب
/// التوكن.
abstract interface class TopUpRepository {
  Future<Either<Failure, TopUpMethods>> methods();

  Future<Either<Failure, TopUpQuote>> quote({required int method, required String amount});

  /// يبدأ الشحن. الرمزُ نفسه ثانيةً يعود بالمحاولة الأولى ولا يبدأ أخرى.
  Future<Either<Failure, TopUpAnswer>> start(TopUpRequest request);

  /// الرمز الذي وصل برسالة. رمزٌ خاطئ يُبقي المحاولة تنتظر بفرصةٍ أقل.
  Future<Either<Failure, TopUpAnswer>> confirmOtp(String attemptId, String otp);

  /// أين وصلت المحاولة — للقراءة وحدها.
  Future<Either<Failure, TopUpAnswer>> show(String attemptId);
}

/// Fulfils [TopUpRepository] over HTTP.
class TopUpRepositoryImpl implements TopUpRepository {
  const TopUpRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, TopUpMethods>> methods() => safeRequest<TopUpMethods>(
    () => _dio.get(TopUpEndpoints.methods),
    parse: (data) => TopUpMethods.fromJson(data as Map<String, dynamic>),
  );

  @override
  Future<Either<Failure, TopUpQuote>> quote({required int method, required String amount}) =>
      safeRequest<TopUpQuote>(
        () => _dio.post(TopUpEndpoints.quote, data: <String, dynamic>{'method': method, 'amount': amount}),
        parse: (data) => TopUpQuote.fromJson(data as Map<String, dynamic>),
      );

  @override
  Future<Either<Failure, TopUpAnswer>> start(TopUpRequest request) => safeRequest<TopUpAnswer>(
    () => _dio.post(TopUpEndpoints.start, data: request.toJson()),
    parse: (data) => TopUpAnswer.fromJson(data as Map<String, dynamic>),
  );

  @override
  Future<Either<Failure, TopUpAnswer>> confirmOtp(String attemptId, String otp) =>
      safeRequest<TopUpAnswer>(
        () => _dio.post(TopUpEndpoints.otp(attemptId), data: <String, dynamic>{'otp': otp.trim()}),
        parse: (data) => TopUpAnswer.fromJson(data as Map<String, dynamic>),
      );

  @override
  Future<Either<Failure, TopUpAnswer>> show(String attemptId) => safeRequest<TopUpAnswer>(
    () => _dio.get(TopUpEndpoints.show(attemptId)),
    parse: (data) => TopUpAnswer.fromJson(data as Map<String, dynamic>),
  );
}
