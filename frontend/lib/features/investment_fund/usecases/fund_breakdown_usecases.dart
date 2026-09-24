import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/repositories/fund_breakdown_repository.dart';

/// سجلُّ الخزينة — «من أين أتى هذا النقد».
class GetFundCash {
  const GetFundCash(this._repository);

  final FundBreakdownRepository _repository;

  Future<Either<Failure, Paginated<FundCashEntry>>> call({required int page}) =>
      _repository.cash(page: page);
}

/// ما دفع الصندوقُ ثمنَه ولم يصل بعد.
class GetFundOnOrder {
  const GetFundOnOrder(this._repository);

  final FundBreakdownRepository _repository;

  Future<Either<Failure, FundOnOrder>> call() => _repository.onOrder();
}

/// ما على الرفّ من بضاعة الصندوق.
class GetFundShelf {
  const GetFundShelf(this._repository);

  final FundBreakdownRepository _repository;

  Future<Either<Failure, FundShelf>> call() => _repository.shelf();
}

/// طلبياتُ البضاعة الخارجة — في الطريق، أو عند عميلٍ لم يدفع.
class GetFundGoodsOut {
  const GetFundGoodsOut(this._repository);

  final FundBreakdownRepository _repository;

  Future<Either<Failure, FundGoodsOut>> call(FundGoodsStage stage) =>
      _repository.goodsOut(stage);
}

/// الأرباحُ المستحقّة للمستثمرين بطلبياتها.
class GetFundProfitOwed {
  const GetFundProfitOwed(this._repository);

  final FundBreakdownRepository _repository;

  Future<Either<Failure, FundProfitOwed>> call() => _repository.profitOwed();
}
