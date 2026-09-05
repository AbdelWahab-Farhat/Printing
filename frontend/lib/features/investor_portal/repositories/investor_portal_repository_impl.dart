import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/repositories/investor_portal_repository.dart';
import 'package:dio/dio.dart';

class InvestorPortalRepositoryImpl implements InvestorPortalRepository {
  const InvestorPortalRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, InvestorPortfolio>> portfolio() {
    return safeRequest<InvestorPortfolio>(
      () => _dio.get(InvestorEndpoints.portalSummary),
      parse: (data) => InvestorPortfolio.fromJson(data as Map<String, dynamic>),
    );
  }
}
