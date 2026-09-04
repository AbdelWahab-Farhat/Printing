import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';

/// The investor's own reading of his account.
///
/// One method, and that is the point: he has exactly one endpoint, and there is nothing else in
/// the system he can reach.
abstract class InvestorPortalRepository {
  Future<Either<Failure, InvestorPortfolio>> portfolio();
}
