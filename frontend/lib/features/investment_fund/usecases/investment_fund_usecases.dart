import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';

class GetFundStanding {
  const GetFundStanding(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, FundStanding>> call() => _repository.standing();
}

class OpenFundPeriod {
  const OpenFundPeriod(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, FundPeriod>> call() => _repository.openPeriod();
}

class CloseFundPeriod {
  const CloseFundPeriod(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, FundPeriod>> call({String? overrideReason}) =>
      _repository.closePeriod(overrideReason: overrideReason);
}

class GetFundPeriods {
  const GetFundPeriods(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, List<FundPeriod>>> call() => _repository.periods();
}

/// طلبياتُ فترةٍ واحدة ومن أخذ منها — ما تُبنى عليه شاشةُ الفترة.
class GetPeriodOrders {
  const GetPeriodOrders(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, PeriodOrders>> call(int periodId) =>
      _repository.periodOrders(periodId);
}

/// إيداعُ رأس مال — يشتري وحداتٍ بسعر اليوم ويحبسها بمدّة فترتها.
class DepositCapital {
  const DepositCapital(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, DepositReceipt>> call({
    required int investorId,
    required String amount,
    String? notes,
  }) => _repository.deposit(
    investorId: investorId,
    amount: amount,
    notes: notes,
  );
}

/// سحبُ رأس مال — يُلغي وحداتِه معه.
class WithdrawCapital {
  const WithdrawCapital(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int investorId,
    required String amount,
    String? notes,
  }) => _repository.withdraw(
    investorId: investorId,
    amount: amount,
    notes: notes,
  );
}

class RecordFundExpense {
  const RecordFundExpense(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) => _repository.recordExpense(
    kind: kind,
    name: name,
    amount: amount,
    incurredOn: incurredOn,
    notes: notes,
  );
}

/// ما يُطلب من الصندوق مع أمر شراء: أيَّ الرفوف يأخذ، وبكم تشتري المطبعةُ سادةَ كلٍّ منها.
///
/// **رفٌّ بلا سعرٍ هنا ليس رفّاً بسعرِ صفر**: الغائبُ عن [printingSalePrices] يمشي على الطريق
/// الآخر — يركب البيعَ إلى التسليم — وهو ما كان يفعله كلُّ رفٍّ قبل أن يوجد هذا الحقل.
typedef FundPurchaseRequest = ({
  List<int> stockItemIds,
  Map<int, String> printingSalePrices,
});

/// شراءُ أمرِ شراءٍ بمال الصندوق — من شاشة الأمر، أو في الضغطة التي أنشأته.
class BuyWithFund {
  const BuyWithFund(this._repository);

  final InvestmentFundRepository _repository;

  Future<Either<Failure, Unit>> call(
    int purchaseOrderId,
    FundPurchaseRequest request,
  ) => _repository.buyPurchaseOrder(
    purchaseOrderId: purchaseOrderId,
    stockItemIds: request.stockItemIds,
    printingSalePrices: request.printingSalePrices,
  );
}
