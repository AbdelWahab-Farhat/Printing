import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';

/// مصاريفُ فترةٍ واحدة، وما تحمّله المستثمرون منها.
class GetPeriodExpenses {
  const GetPeriodExpenses(this._repository);

  final PeriodExpensesRepository _repository;

  Future<Either<Failure, PeriodExpenses>> call(int periodId) =>
      _repository.periodExpenses(periodId);
}

/// عكسُ مصروفٍ على الصندوق.
class ReverseFundExpense {
  const ReverseFundExpense(this._repository);

  final PeriodExpensesRepository _repository;

  Future<Either<Failure, Unit>> call(int expenseId, {required String reason}) =>
      _repository.reverseExpense(expenseId, reason: reason);
}
