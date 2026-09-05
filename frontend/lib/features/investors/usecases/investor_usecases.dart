import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';

/// One page of the investors list.
class GetInvestors {
  const GetInvestors(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Paginated<Investor>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
    // silently finds nothing, and every caller would otherwise have to remember it.
    return _repository.investors(
      search: search?.trim(),
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}

class GetInvestor {
  const GetInvestor(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Investor>> call(int id) => _repository.investor(id);
}

class CreateInvestor {
  const CreateInvestor(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Investor>> call({
    required String name,
    String? phone,
    String? notes,
  }) => _repository.createInvestor(name: name.trim(), phone: phone?.trim(), notes: notes?.trim());
}

class RecordWalletEntry {
  const RecordWalletEntry(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int investorId,
    required String type,
    required String amount,
    int? investorDealId,
    String? method,
    String? reference,
    String? notes,
  }) => _repository.recordWalletEntry(
    investorId: investorId,
    type: type,
    // ٢٥٠٠ is what an Arabic keyboard produces, and the server's `numeric` rule refuses it —
    // «المبلغ يجب أن يكون رقماً» about a number the person can see they typed. Converted here
    // rather than in the field: a validator that rewrote the box would change a figure under
    // somebody's finger. The field's own formatter is what keeps a comma out.
    amount: Validators.toWesternDigits(amount.trim()),
    investorDealId: investorDealId,
    method: method,
    reference: reference,
    notes: notes,
  );
}

class GetInvestorDeals {
  const GetInvestorDeals(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Paginated<InvestorDeal>>> call({
    String? search,
    String? status,
    int? investorId,
    int page = 1,
    int perPage = 20,
  }) => _repository.deals(
    search: search?.trim(),
    status: status,
    investorId: investorId,
    page: page,
    perPage: perPage,
  );
}

class GetInvestorDeal {
  const GetInvestorDeal(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, InvestorDeal>> call(int id) => _repository.deal(id);
}

/// The orders that sold one deal's goods, and what each one earned it.
class GetDealOrders {
  const GetDealOrders(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Paginated<DealOrder>>> call(
    int dealId, {
    int page = 1,
    int perPage = 20,
  }) => _repository.dealOrders(dealId, page: page, perPage: perPage);
}

/// Funding a purchase order — the only way a deal is born.
///
/// There is no use case that creates a deal by hand: the fraction of the goods its partners own
/// is derived from the order's cost, which a deal without an order would not have.
class FundPurchaseOrder {
  const FundPurchaseOrder(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, InvestorDeal>> call(
    int purchaseOrderId,
    Map<String, dynamic> body,
  ) => _repository.fundPurchaseOrder(purchaseOrderId, body);
}

/// Closing a deal — the one state change a person makes. Opening happens with the funding.
class ChangeDealState {
  const ChangeDealState(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, InvestorDeal>> close(int id) => _repository.closeDeal(id);
}

class RecordDealExpense {
  const RecordDealExpense(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int dealId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) => _repository.recordExpense(
    dealId: dealId,
    kind: kind,
    name: name.trim(),
    // Converted for the same reason the wallet entry beside it is: ٢٥٠٠ is what the keyboard
    // under a Libyan thumb produces, and the server's `numeric` rule refuses it.
    amount: Validators.toWesternDigits(amount.trim()),
    incurredOn: incurredOn,
    notes: notes?.trim(),
  );
}
