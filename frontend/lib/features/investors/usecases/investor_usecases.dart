import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
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
    amount: amount,
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

class CreateInvestorDeal {
  const CreateInvestorDeal(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, InvestorDeal>> call(Map<String, dynamic> body) =>
      _repository.createDeal(body);
}

class ChangeDealState {
  const ChangeDealState(this._repository);

  final InvestorRepository _repository;

  Future<Either<Failure, InvestorDeal>> open(int id) => _repository.openDeal(id);

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
    amount: amount,
    incurredOn: incurredOn,
    notes: notes?.trim(),
  );
}
