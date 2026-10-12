import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';

/// مصاريفُ الفترة — بعقدٍ منفصلٍ عن إدارة الصندوق، كما «ما وراء كلّ بند».
abstract interface class PeriodExpensesRepository {
  /// مصاريفُ فترةٍ واحدة، وما تحمّله كلُّ مستثمرٍ من كلٍّ منها.
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId);

  /// «مصاريف الصندوق» كلُّها، الأحدثُ أوّلاً، أو مصاريفُ فترةٍ واحدة بـ[periodId] — و`expenses_total`
  /// في `extraMeta` مجموعُها على الخادم.
  Future<Either<Failure, Paginated<FundExpense>>> fundExpenses({int? periodId, required int page});

  /// يعكس مصروفاً على الصندوق بسببٍ يُكتب على صفّ العكس.
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason});
}
