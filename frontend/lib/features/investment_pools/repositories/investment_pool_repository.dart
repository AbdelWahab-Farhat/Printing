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

/// صناديق الاستثمار — the continuous pools, their periods, and the money that moves through them.
///
/// **Separate from `InvestorRepository`, and permanently.** The صفقة is read-only but still alive:
/// closed deals keep their screens and their arithmetic. One repository covering both would invite
/// a screen to call the wrong half, and would hide the fact that these are two different models of
/// ownership rather than two versions of one.
abstract class InvestmentPoolRepository {
  Future<Either<Failure, Paginated<InvestmentPool>>> pools({
    String? search,
    int? investorId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  });

  /// One pool, with its shelves, its members and its `capital_timing`.
  Future<Either<Failure, InvestmentPool>> pool(int id);

  /// Opens a pool over the given shelves.
  ///
  /// Refused if any shelf already belongs to another pool, or if a product standing on one is
  /// outside the investable headings. [investorProfitSharePercent] may be given once, here, and is
  /// seeded from the company default when it is omitted.
  Future<Either<Failure, InvestmentPool>> createPool({
    required String name,
    required List<int> stockItemIds,
    String? investorProfitSharePercent,
    String? notes,
  });

  /// Renames a pool or changes which shelves it buys.
  ///
  /// **Moves no stock.** Cost layers keep the pool they were opened with for ever — they are what
  /// that pool's investors paid for — so this decides where the *next* lorry goes and nothing
  /// else, which is why it is safe while a period is open.
  Future<Either<Failure, InvestmentPool>> updatePool({
    required int id,
    required String name,
    required List<int> stockItemIds,
    String? notes,
  });

  Future<Either<Failure, List<InvestmentPeriod>>> periods(int poolId);

  /// Opens the pool's next period. Its dates come from the company calendar — never from here —
  /// and the capital queued for this boundary is let in at the same moment.
  Future<Either<Failure, PeriodOpened>> openPeriod(int poolId);

  /// What the period has made so far, and whether anything is holding its close up. **The same
  /// arithmetic the close performs**, which is why the close screen prints this and not its own.
  Future<Either<Failure, PeriodFigures>> periodFigures(int periodId);

  /// Divides the period, releases profit into wallets, pays whoever asked to leave, and opens the
  /// next one. **Irreversible**, and refused while a returned-goods question is unanswered.
  Future<Either<Failure, InvestmentPeriod>> closePeriod(int periodId);

  /// Who got what in a closed period — the weights that were applied and the amounts that were
  /// paid. Empty on an open period: nothing has been divided yet.
  Future<Either<Failure, List<PeriodShare>>> periodShares(int periodId);

  Future<Either<Failure, List<CapitalRequest>>> capitalRequests(int poolId);

  /// Offers capital to the pool or asks for it back.
  ///
  /// Read the pool's `capital_timing` first and show what it says: inside the grace window the
  /// money is taken now, outside it the request waits for the next boundary. A withdrawal is
  /// always queued, and executes at the close **after** that period's profit is divided.
  Future<Either<Failure, CapitalRequest>> requestCapital({
    required int poolId,
    required int investorId,
    required String direction,
    required String amount,
    String? notes,
  });

  /// Only before it has taken effect. Unwinds nothing, because a pending request never moved
  /// money — the deposit has been in the investor's own wallet the whole time.
  Future<Either<Failure, CapitalRequest>> cancelCapitalRequest(int requestId);

  Future<Either<Failure, PoolDeployableCash>> deployableCash(int poolId);

  /// Material a cancelled printed order gave back. Pass [onlyOpen] on a close screen — the open
  /// ones are the work, and they are what the close is waiting for.
  Future<Either<Failure, List<ReturnedGoodsQuestion>>> returnedGoods({
    required int poolId,
    bool onlyOpen = false,
  });

  /// «صالحة» writes nothing; «تالفة» posts a damage adjustment and the goods leave the shelf.
  /// Answered once — a verdict is not a draft.
  Future<Either<Failure, ReturnedGoodsQuestion>> answerReturnedGoods({
    required int questionId,
    required String verdict,
    required int warehouseId,
    String? notes,
  });

  /// Where the pool's money is, derived now. Its `drift` is the comparison this feature exists
  /// for, and a non-zero one is a finding.
  Future<Either<Failure, SettlementSnapshot>> settlementSnapshot(int poolId);

  Future<Either<Failure, List<InvestmentSettlement>>> settlements(int poolId);

  /// Freezes that position and signs it. **Moves nothing.** Carries no figures and no period
  /// range: both are walked at the moment of signing.
  Future<Either<Failure, InvestmentSettlement>> recordSettlement({
    required int poolId,
    String? settledOn,
    int? approvedBy,
    String? notes,
  });

  /// What has been charged to the pool, newest first.
  Future<Either<Failure, List<PoolExpense>>> expenses(int poolId);

  /// Charges a cost to the pool — storage, internal transport, and the like.
  ///
  /// **Charged to a period, not dated into one.** A closed period is immutable, so an October
  /// invoice bearing a September date is charged to October and keeps its true `incurredOn` with a
  /// note saying where it was meant for.
  ///
  /// Whether it is actually **subtracted** is the server's decision, not this call's: shipping and
  /// customs typed on a purchase order arrive as «محسوبة مسبقاً» — already inside the cost of the
  /// layers that landed — and are recorded without being deducted a second time.
  Future<Either<Failure, Unit>> recordExpense({
    required int poolId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  });

  /// Marks lines of a purchase order as bought with pool money.
  ///
  /// **No pool is named.** Each material belongs to exactly one, so the only decision per line is
  /// pool money or the company's — and `printingSalePrice` is سعر السادة for that lorry, omitted
  /// when those goods should ride the sale instead.
  Future<Either<Failure, Unit>> buyWithPoolMoney({
    required int purchaseOrderId,
    required List<PoolPurchaseLine> lines,
  });
}

/// One line of a lorry, marked for pool money.
class PoolPurchaseLine {
  const PoolPurchaseLine({required this.stockItemId, this.printingSalePrice});

  final int stockItemId;

  /// سعر السادة — what the press pays the pool for a unit of this plain stock. **Null is not
  /// zero**: it puts these goods on the other road, where the partners ride the sale itself.
  final String? printingSalePrice;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'stock_item_id': stockItemId,
    if (printingSalePrice != null) 'printing_sale_price': printingSalePrice,
  };
}
