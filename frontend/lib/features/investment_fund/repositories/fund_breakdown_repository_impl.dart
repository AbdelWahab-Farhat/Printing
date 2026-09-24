import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/repositories/fund_breakdown_repository.dart';
import 'package:dio/dio.dart';

class FundBreakdownRepositoryImpl implements FundBreakdownRepository {
  const FundBreakdownRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<FundCashEntry>>> cash({required int page}) {
    return safePaginatedRequest<FundCashEntry>(
      () => _dio.get(InvestmentEndpoints.fundCash, queryParameters: {'page': page}),
      parseItem: FundCashEntry.fromJson,
    );
  }

  @override
  Future<Either<Failure, FundOnOrder>> onOrder() {
    return safeRequest<FundOnOrder>(
      () => _dio.get(InvestmentEndpoints.fundOnOrder),
      parse: (data) => FundOnOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, FundShelf>> shelf() {
    return safeRequest<FundShelf>(
      () => _dio.get(InvestmentEndpoints.fundShelf),
      parse: (data) => FundShelf.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, FundGoodsOut>> goodsOut(FundGoodsStage stage) {
    return safeRequest<FundGoodsOut>(
      () => _dio.get(switch (stage) {
        FundGoodsStage.inFlight => InvestmentEndpoints.fundInFlight,
        FundGoodsStage.uncollected => InvestmentEndpoints.fundReceivables,
      }),
      parse: (data) => FundGoodsOut.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, FundProfitOwed>> profitOwed() {
    return safeRequest<FundProfitOwed>(
      () => _dio.get(InvestmentEndpoints.fundProfitOwed),
      parse: (data) => FundProfitOwed.fromJson(data as Map<String, dynamic>),
    );
  }
}
