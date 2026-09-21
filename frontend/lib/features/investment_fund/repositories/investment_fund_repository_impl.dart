import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dio/dio.dart';

class InvestmentFundRepositoryImpl implements InvestmentFundRepository {
  const InvestmentFundRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, FundStanding>> standing() {
    return safeRequest<FundStanding>(
      () => _dio.get(InvestmentEndpoints.fund),
      parse: (data) => FundStanding.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, FundPeriod>> openPeriod() {
    return safeRequest<FundPeriod>(
      () => _dio.post(InvestmentEndpoints.periods),
      parse: (data) => FundPeriod.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason}) {
    return safeRequest<FundPeriod>(
      () => _dio.post(
        InvestmentEndpoints.closePeriod,
        // يُحذف لا يُرسَل فارغاً: null في الجسد يصل «null» نصّاً فيُقرأ سبباً.
        data: {'override_reason': ?overrideReason},
      ),
      parse: (data) => FundPeriod.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<FundPeriod>>> periods() {
    return safeRequest<List<FundPeriod>>(
      () => _dio.get(InvestmentEndpoints.periods),
      parse: (data) => (data as List<dynamic>)
          .map((row) => FundPeriod.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, PeriodOrders>> periodOrders(int periodId) {
    return safeRequest<PeriodOrders>(
      () => _dio.get(InvestmentEndpoints.periodOrders(periodId)),
      parse: (data) => PeriodOrders.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DepositReceipt>> deposit({
    required int investorId,
    required String amount,
    String? notes,
  }) {
    return safeRequest<DepositReceipt>(
      () => _dio.post(
        InvestmentEndpoints.deposits,
        data: {'investor_id': investorId, 'amount': amount, 'notes': ?notes},
      ),
      parse: (data) => DepositReceipt.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> withdraw({
    required int investorId,
    required String amount,
    String? notes,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestmentEndpoints.withdrawals,
        data: {'investor_id': investorId, 'amount': amount, 'notes': ?notes},
      ),
      parse: (_) => unit,
    );
  }

  @override
  Future<Either<Failure, Unit>> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestmentEndpoints.expenses,
        data: {
          'kind': kind,
          'name': name,
          'amount': amount,
          'incurred_on': incurredOn,
          'notes': ?notes,
        },
      ),
      parse: (_) => unit,
    );
  }
}
