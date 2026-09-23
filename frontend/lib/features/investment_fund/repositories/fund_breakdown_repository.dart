import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';

/// ما وراء كلِّ بندٍ في لوحة الصندوق — قراءةٌ كلُّها.
///
/// **عقدٌ منفصلٌ عن `InvestmentFundRepository` عن قصد**: ذاك يدير الصندوق — يفتح فترةً ويقفلها
/// ويقبض ويصرف — وهذا يقرأ ما صنعته تلك الحركات. شاشةٌ تفتح سجلَّ الخزينة لا تحتاج أن تعرف
/// كيف يُقفَل شهر.
abstract interface class FundBreakdownRepository {
  /// سجلُّ الخزينة صفحةً صفحة، الأحدثُ أوّلاً — و`balance` في `extraMeta` نقدُ اللوحة بعينه.
  Future<Either<Failure, Paginated<FundCashEntry>>> cash({required int page});

  /// بضاعةُ الصندوق على الرفّ، مادّةً مادّة.
  Future<Either<Failure, FundShelf>> shelf();

  /// طلبياتُ بندٍ من بندَي البضاعة الخارجة، وما أخذته كلٌّ منها.
  Future<Either<Failure, FundGoodsOut>> goodsOut(FundGoodsStage stage);

  /// الأرباحُ المستحقّة: ما لم يُفرَج عنه بطلبياته، وما في المحافظ بأصحابه.
  Future<Either<Failure, FundProfitOwed>> profitOwed();
}
