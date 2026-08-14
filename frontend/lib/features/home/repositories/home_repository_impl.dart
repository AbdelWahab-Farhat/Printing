import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/repositories/home_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [HomeRepository] over HTTP.
///
/// **This file was a fixed snapshot until the endpoint existed**, and the note it carried said
/// that when the endpoint landed this file — and only this file — would change. It did: the
/// models already held their `@JsonKey` names, so the Cubit, the screen and every test above
/// this line are untouched.
///
/// The status rows are no longer the paper workflow's («عربون مدفوع», «مرفوض»). They are the
/// app's own statuses now, sent by the server with the Arabic already on them, which is why this
/// class still holds no list of its own.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, HomeSummary>> summary() {
    return safeRequest<HomeSummary>(
      () => _dio.get(HomeEndpoints.summary),
      parse: (data) => HomeSummary.fromJson(data as Map<String, dynamic>),
    );
  }
}
