import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';

/// «مصاريف الصندوق» — كلُّها الأحدثُ أوّلاً، أو مصاريفُ فترةٍ واحدة.
///
/// **الفلترُ سؤالٌ جديد للخادم، لا تصفيةٌ لما حُمِّل**: الصفحةُ الأولى عشرون سطراً، ومجموعُ الفترة
/// ([total]) جوابُ الخادم على كلّ ما طابق.
class FundExpensesCubit extends PagedCubit<FundExpense> {
  FundExpensesCubit({required GetFundExpenses getExpenses}) : _getExpenses = getExpenses;

  final GetFundExpenses _getExpenses;

  /// الفترةُ المختارة — `null` لـ«الكل».
  int? periodId;

  /// المجموعُ كما قاله الخادم للفلتر، و«0.00» قبل أن يجيب.
  String get total => switch (state) {
    PagedLoaded(:final page) => '${page.extraMeta['expenses_total'] ?? '0.00'}',
    _ => '0.00',
  };

  /// يقصر القائمة على فترة، أو يعيدها إلى «الكل» بـ`null`.
  Future<void> showPeriod(int? id) {
    if (id == periodId) return Future<void>.value();

    periodId = id;

    return load();
  }

  @override
  Object identityOf(FundExpense item) => item.id;

  @override
  Future<Either<Failure, Paginated<FundExpense>>> fetchPage({String? search, required int page}) =>
      _getExpenses(periodId: periodId, page: page);
}
