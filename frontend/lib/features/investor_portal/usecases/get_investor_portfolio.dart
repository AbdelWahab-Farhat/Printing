import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/repositories/investor_portal_repository.dart';

class GetInvestorPortfolio {
  const GetInvestorPortfolio(this._repository);

  final InvestorPortalRepository _repository;

  Future<Either<Failure, InvestorPortfolio>> call() => _repository.portfolio();
}
