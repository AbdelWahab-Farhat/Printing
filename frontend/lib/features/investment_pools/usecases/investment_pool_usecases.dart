import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/investment_pools/models/capital_request.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/models/investment_settlement.dart';
import 'package:dayaa/features/investment_pools/models/period_share.dart';
import 'package:dayaa/features/investment_pools/models/pool_expense.dart';
import 'package:dayaa/features/investment_pools/models/returned_goods_question.dart';
import 'package:dayaa/features/investment_pools/repositories/investment_pool_repository.dart';

/// One page of the pools list.
class GetInvestmentPools {
  const GetInvestmentPools(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, Paginated<InvestmentPool>>> call({
    String? search,
    int? investorId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
    // silently finds nothing, and every caller would otherwise have to remember it.
    return _repository.pools(
      search: search?.trim(),
      investorId: investorId,
      stockItemId: stockItemId,
      page: page,
      perPage: perPage,
    );
  }
}

class GetInvestmentPool {
  const GetInvestmentPool(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, InvestmentPool>> call(int id) => _repository.pool(id);
}

class CreateInvestmentPool {
  const CreateInvestmentPool(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, InvestmentPool>> call({
    required String name,
    required List<int> stockItemIds,
    String? investorProfitSharePercent,
    String? notes,
  }) => _repository.createPool(
    name: name.trim(),
    stockItemIds: stockItemIds,
    investorProfitSharePercent: investorProfitSharePercent?.trim(),
    notes: notes?.trim(),
  );
}

class UpdateInvestmentPool {
  const UpdateInvestmentPool(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, InvestmentPool>> call({
    required int id,
    required String name,
    required List<int> stockItemIds,
    String? notes,
  }) => _repository.updatePool(
    id: id,
    name: name.trim(),
    stockItemIds: stockItemIds,
    notes: notes?.trim(),
  );
}

class GetPoolPeriods {
  const GetPoolPeriods(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<InvestmentPeriod>>> call(int poolId) =>
      _repository.periods(poolId);
}

class OpenInvestmentPeriod {
  const OpenInvestmentPeriod(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, PeriodOpened>> call(int poolId) =>
      _repository.openPeriod(poolId);
}

class GetPeriodFigures {
  const GetPeriodFigures(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, PeriodFigures>> call(int periodId) =>
      _repository.periodFigures(periodId);
}

/// Divides a period and pays it out. **Irreversible.**
class CloseInvestmentPeriod {
  const CloseInvestmentPeriod(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, InvestmentPeriod>> call(int periodId) =>
      _repository.closePeriod(periodId);
}

class GetPeriodShares {
  const GetPeriodShares(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<PeriodShare>>> call(int periodId) =>
      _repository.periodShares(periodId);
}

class GetCapitalRequests {
  const GetCapitalRequests(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<CapitalRequest>>> call(int poolId) =>
      _repository.capitalRequests(poolId);
}

class RequestPoolCapital {
  const RequestPoolCapital(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, CapitalRequest>> call({
    required int poolId,
    required int investorId,
    required String direction,
    required String amount,
    String? notes,
  }) => _repository.requestCapital(
    poolId: poolId,
    investorId: investorId,
    direction: direction,
    amount: amount.trim(),
    notes: notes?.trim(),
  );
}

class CancelCapitalRequest {
  const CancelCapitalRequest(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, CapitalRequest>> call(int requestId) =>
      _repository.cancelCapitalRequest(requestId);
}

class GetPoolDeployableCash {
  const GetPoolDeployableCash(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, PoolDeployableCash>> call(int poolId) =>
      _repository.deployableCash(poolId);
}

class GetReturnedGoods {
  const GetReturnedGoods(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<ReturnedGoodsQuestion>>> call({
    required int poolId,
    bool onlyOpen = false,
  }) => _repository.returnedGoods(poolId: poolId, onlyOpen: onlyOpen);
}

/// «صالحة» أو «تالفة». Answered once.
class AnswerReturnedGoods {
  const AnswerReturnedGoods(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, ReturnedGoodsQuestion>> call({
    required int questionId,
    required String verdict,
    required int warehouseId,
    String? notes,
  }) => _repository.answerReturnedGoods(
    questionId: questionId,
    verdict: verdict,
    warehouseId: warehouseId,
    notes: notes?.trim(),
  );
}

class GetSettlementSnapshot {
  const GetSettlementSnapshot(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, SettlementSnapshot>> call(int poolId) =>
      _repository.settlementSnapshot(poolId);
}

class GetSettlements {
  const GetSettlements(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<InvestmentSettlement>>> call(int poolId) =>
      _repository.settlements(poolId);
}

/// Signs a position. Moves nothing.
class RecordSettlement {
  const RecordSettlement(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, InvestmentSettlement>> call({
    required int poolId,
    String? settledOn,
    int? approvedBy,
    String? notes,
  }) => _repository.recordSettlement(
    poolId: poolId,
    settledOn: settledOn,
    approvedBy: approvedBy,
    notes: notes?.trim(),
  );
}

class GetPoolExpenses {
  const GetPoolExpenses(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, List<PoolExpense>>> call(int poolId) =>
      _repository.expenses(poolId);
}

class RecordPoolExpense {
  const RecordPoolExpense(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int poolId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) => _repository.recordExpense(
    poolId: poolId,
    kind: kind,
    name: name.trim(),
    amount: amount.trim(),
    incurredOn: incurredOn,
    notes: notes?.trim(),
  );
}

class BuyWithPoolMoney {
  const BuyWithPoolMoney(this._repository);

  final InvestmentPoolRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int purchaseOrderId,
    required List<PoolPurchaseLine> lines,
  }) => _repository.buyWithPoolMoney(
    purchaseOrderId: purchaseOrderId,
    lines: lines,
  );
}
