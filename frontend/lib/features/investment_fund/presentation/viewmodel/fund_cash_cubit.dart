import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';

/// سجلُّ خزينة الصندوق — الأحدثُ أوّلاً، صفحةً صفحة.
///
/// قراءةٌ فقط: كلُّ صفٍّ هنا أثرُ حدثٍ في مكانٍ آخر — إيداعٍ أو شراءٍ أو تحصيل — ولا يُكتب من
/// هذه الشاشة شيء.
class FundCashCubit extends PagedCubit<FundCashEntry> {
  FundCashCubit({required GetFundCash getCash}) : _getCash = getCash;

  final GetFundCash _getCash;

  @override
  Object identityOf(FundCashEntry item) => item.id;

  @override
  Future<Either<Failure, Paginated<FundCashEntry>>> fetchPage({String? search, required int page}) =>
      _getCash(page: page);
}

typedef FundCashState = PagedState<FundCashEntry>;
typedef FundCashLoaded = PagedLoaded<FundCashEntry>;

/// نقدُ الخزينة كما يقوله الخادم مع كلّ صفحة — `null` قبل أن تصل الأولى.
///
/// **لا يُجمع من الصفوف هنا**: الصفحةُ الأولى ثلاثون صفّاً من دفترٍ قد يطول سنة، ومجموعُها ليس
/// ما في الخزينة.
String? fundCashBalanceOf(FundCashState state) =>
    state is FundCashLoaded ? state.page.extraMeta['balance'] as String? : null;
