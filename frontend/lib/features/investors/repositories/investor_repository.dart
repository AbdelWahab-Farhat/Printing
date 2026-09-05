import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';

/// The staff side of investors: the people, their money, and their deals.
abstract class InvestorRepository {
  Future<Either<Failure, Paginated<Investor>>> investors({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, Investor>> investor(int id);

  Future<Either<Failure, Investor>> createInvestor({
    required String name,
    String? phone,
    String? notes,
  });

  /// One movement of his money. Only the four types a person may record are ever sent — an
  /// earning is written by the order that produced it, and offering it on a form would be
  /// offering somebody the chance to invent one.
  Future<Either<Failure, Unit>> recordWalletEntry({
    required int investorId,
    required String type,
    required String amount,
    int? investorDealId,
    String? method,
    String? reference,
    String? notes,
  });

  Future<Either<Failure, Paginated<InvestorDeal>>> deals({
    String? search,
    String? status,
    int? investorId,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, InvestorDeal>> deal(int id);

  /// The orders that sold a deal's goods, newest first — what each one drew off its shelves
  /// and what that earned. An order still on the road is on the list with nothing paid for it
  /// yet; a cancelled one is absent, because its goods went back into this deal's own layers.
  Future<Either<Failure, Paginated<DealOrder>>> dealOrders(
    int dealId, {
    int page,
    int perPage,
  });

  /// Funds one purchase order: creates the deal, inherits its lines, claims every one of them
  /// and moves the money — the server does all four or none.
  Future<Either<Failure, InvestorDeal>> fundPurchaseOrder(
    int purchaseOrderId,
    Map<String, dynamic> body,
  );

  Future<Either<Failure, InvestorDeal>> closeDeal(int id);

  Future<Either<Failure, Unit>> recordExpense({
    required int dealId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  });
}
