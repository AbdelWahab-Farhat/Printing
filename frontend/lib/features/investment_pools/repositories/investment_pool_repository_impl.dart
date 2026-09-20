import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investment_pools/models/capital_request.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/models/investment_settlement.dart';
import 'package:dayaa/features/investment_pools/models/period_share.dart';
import 'package:dayaa/features/investment_pools/models/pool_expense.dart';
import 'package:dayaa/features/investment_pools/models/returned_goods_question.dart';
import 'package:dayaa/features/investment_pools/repositories/investment_pool_repository.dart';
import 'package:dio/dio.dart';

class InvestmentPoolRepositoryImpl implements InvestmentPoolRepository {
  const InvestmentPoolRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<InvestmentPool>>> pools({
    String? search,
    int? investorId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<InvestmentPool>(
      () => _dio.get(
        InvestmentPoolEndpoints.pools,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          'investor_id': ?investorId,
          'stock_item_id': ?stockItemId,
        },
      ),
      parseItem: (row) => InvestmentPool.fromJson(row),
    );
  }

  @override
  Future<Either<Failure, InvestmentPool>> pool(int id) {
    return safeRequest<InvestmentPool>(
      () => _dio.get(InvestmentPoolEndpoints.pool(id)),
      parse: (data) => InvestmentPool.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestmentPool>> createPool({
    required String name,
    required List<int> stockItemIds,
    String? investorProfitSharePercent,
    String? notes,
  }) {
    return safeRequest<InvestmentPool>(
      () => _dio.post(
        InvestmentPoolEndpoints.pools,
        data: <String, dynamic>{
          'name': name,
          'stock_item_ids': stockItemIds,
          'investor_profit_share_percent': ?investorProfitSharePercent,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) => InvestmentPool.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestmentPool>> updatePool({
    required int id,
    required String name,
    required List<int> stockItemIds,
    String? notes,
  }) {
    return safeRequest<InvestmentPool>(
      () => _dio.put(
        InvestmentPoolEndpoints.pool(id),
        data: <String, dynamic>{
          'name': name,
          'stock_item_ids': stockItemIds,
          'notes': ?notes,
        },
      ),
      parse: (data) => InvestmentPool.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<InvestmentPeriod>>> periods(int poolId) {
    return safeRequest<List<InvestmentPeriod>>(
      () => _dio.get(InvestmentPoolEndpoints.periods(poolId)),
      parse: (data) => (data as List<dynamic>)
          .map((row) => InvestmentPeriod.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, PeriodOpened>> openPeriod(int poolId) {
    return safeRequest<PeriodOpened>(
      () => _dio.post(InvestmentPoolEndpoints.periods(poolId)),
      parse: (data) => PeriodOpened.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PeriodFigures>> periodFigures(int periodId) {
    return safeRequest<PeriodFigures>(
      () => _dio.get(InvestmentPoolEndpoints.periodFigures(periodId)),
      parse: (data) => PeriodFigures.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestmentPeriod>> closePeriod(int periodId) {
    return safeRequest<InvestmentPeriod>(
      () => _dio.post(InvestmentPoolEndpoints.closePeriod(periodId)),
      parse: (data) => InvestmentPeriod.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<PeriodShare>>> periodShares(int periodId) {
    return safeRequest<List<PeriodShare>>(
      () => _dio.get(InvestmentPoolEndpoints.periodShares(periodId)),
      parse: (data) => (data as List<dynamic>)
          .map((row) => PeriodShare.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, List<CapitalRequest>>> capitalRequests(int poolId) {
    return safeRequest<List<CapitalRequest>>(
      () => _dio.get(InvestmentPoolEndpoints.capitalRequests(poolId)),
      parse: (data) => (data as List<dynamic>)
          .map((row) => CapitalRequest.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, CapitalRequest>> requestCapital({
    required int poolId,
    required int investorId,
    required String direction,
    required String amount,
    String? notes,
  }) {
    return safeRequest<CapitalRequest>(
      () => _dio.post(
        InvestmentPoolEndpoints.capitalRequests(poolId),
        data: <String, dynamic>{
          'investor_id': investorId,
          'direction': direction,
          'amount': amount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) => CapitalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CapitalRequest>> cancelCapitalRequest(int requestId) {
    return safeRequest<CapitalRequest>(
      () => _dio.delete(InvestmentPoolEndpoints.cancelCapitalRequest(requestId)),
      parse: (data) => CapitalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PoolDeployableCash>> deployableCash(int poolId) {
    return safeRequest<PoolDeployableCash>(
      () => _dio.get(InvestmentPoolEndpoints.deployableCash(poolId)),
      parse: (data) => PoolDeployableCash.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<ReturnedGoodsQuestion>>> returnedGoods({
    required int poolId,
    bool onlyOpen = false,
  }) {
    return safeRequest<List<ReturnedGoodsQuestion>>(
      () => _dio.get(
        InvestmentPoolEndpoints.returnedGoods(poolId),
        queryParameters: <String, dynamic>{if (onlyOpen) 'only_open': 1},
      ),
      parse: (data) => (data as List<dynamic>)
          .map(
            (row) => ReturnedGoodsQuestion.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  @override
  Future<Either<Failure, ReturnedGoodsQuestion>> answerReturnedGoods({
    required int questionId,
    required String verdict,
    required int warehouseId,
    String? notes,
  }) {
    return safeRequest<ReturnedGoodsQuestion>(
      () => _dio.post(
        InvestmentPoolEndpoints.answerReturnedGoods(questionId),
        data: <String, dynamic>{
          'verdict': verdict,
          'warehouse_id': warehouseId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) =>
          ReturnedGoodsQuestion.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, SettlementSnapshot>> settlementSnapshot(int poolId) {
    return safeRequest<SettlementSnapshot>(
      () => _dio.get(InvestmentPoolEndpoints.settlementSnapshot(poolId)),
      parse: (data) => SettlementSnapshot.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<InvestmentSettlement>>> settlements(int poolId) {
    return safeRequest<List<InvestmentSettlement>>(
      () => _dio.get(InvestmentPoolEndpoints.settlements(poolId)),
      parse: (data) => (data as List<dynamic>)
          .map(
            (row) => InvestmentSettlement.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  @override
  Future<Either<Failure, InvestmentSettlement>> recordSettlement({
    required int poolId,
    String? settledOn,
    int? approvedBy,
    String? notes,
  }) {
    return safeRequest<InvestmentSettlement>(
      () => _dio.post(
        InvestmentPoolEndpoints.settlements(poolId),
        data: <String, dynamic>{
          'settled_on': ?settledOn,
          'approved_by': ?approvedBy,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) =>
          InvestmentSettlement.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<PoolExpense>>> expenses(int poolId) {
    return safeRequest<List<PoolExpense>>(
      () => _dio.get(InvestmentPoolEndpoints.poolExpenses(poolId)),
      parse: (data) => (data as List<dynamic>)
          .map((row) => PoolExpense.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> recordExpense({
    required int poolId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestmentPoolEndpoints.expenses(poolId),
        data: <String, dynamic>{
          'kind': kind,
          'name': name,
          'amount': amount,
          'incurred_on': incurredOn,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (_) => unit,
    );
  }

  @override
  Future<Either<Failure, Unit>> buyWithPoolMoney({
    required int purchaseOrderId,
    required List<PoolPurchaseLine> lines,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestmentPoolEndpoints.poolPurchase(purchaseOrderId),
        data: <String, dynamic>{
          'lines': lines.map((line) => line.toJson()).toList(),
        },
      ),
      parse: (_) => unit,
    );
  }
}
