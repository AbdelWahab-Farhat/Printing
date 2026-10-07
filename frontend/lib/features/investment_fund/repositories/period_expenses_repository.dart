import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';

/// مصاريفُ الفترة — بعقدٍ منفصلٍ عن إدارة الصندوق، كما «ما وراء كلّ بند».
abstract interface class PeriodExpensesRepository {
  /// مصاريفُ فترةٍ واحدة، وما تحمّله كلُّ مستثمرٍ من كلٍّ منها.
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId);

  /// يعكس مصروفاً على الصندوق بسببٍ يُكتب على صفّ العكس.
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason});
}
