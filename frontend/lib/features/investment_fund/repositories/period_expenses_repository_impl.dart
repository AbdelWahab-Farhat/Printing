import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';
import 'package:dio/dio.dart';

class PeriodExpensesRepositoryImpl implements PeriodExpensesRepository {
  const PeriodExpensesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId) {
    return safeRequest<PeriodExpenses>(
      () => _dio.get(InvestmentEndpoints.periodExpenses(periodId)),
      parse: (data) => PeriodExpenses.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason}) {
    return safeRequest<Unit>(
      () => _dio.post(InvestmentEndpoints.expenseReversal(expenseId), data: {'reason': reason}),
      parse: (_) => unit,
    );
  }
}
