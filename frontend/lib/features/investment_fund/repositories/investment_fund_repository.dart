import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';

abstract interface class InvestmentFundRepository {
  Future<Either<Failure, FundStanding>> standing();

  /// يفتح فترةً على رصيد ما قبلها — **ولا يُصفَّر شيء**.
  Future<Either<Failure, FundPeriod>> openPeriod();

  /// يُقفلها فيُفرج عن أرباحها. [overrideReason] لمن يُقفل قبل نهاية النافذة أو وفيها طلبيةٌ
  /// عالقة — سببٌ يُكتب على صفّها باسم فاعله، لا تجاوزٌ صامت.
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason});

  /// سجلُّ الفترات — المغلقةُ بأرقامها المجمّدة.
  Future<Either<Failure, List<FundPeriod>>> periods();

  /// **اشتراكٌ من المحفظة**: بابٌ واحد يكتب في ثلاثة دفاتر — المحفظةُ والخزينةُ والوحدات. لا
  /// `method` له: المالُ في المحفظة منذ أن سُلِّم على الطاولة، وهذا نقلٌ داخليّ لا يعبر فيه
  /// دينارٌ يداً. وسقفُه رصيدُ محفظته، يفرضه الخادم.
  Future<Either<Failure, DepositReceipt>> deposit({
    required int investorId,
    required String amount,
    String? notes,
  });

  /// يستردّ رأسَ المال إلى محفظته ويُلغي وحداتِه — فلا نسبةَ بلا مال.
  Future<Either<Failure, Unit>> withdraw({
    required int investorId,
    required String amount,
    String? notes,
  });

  /// مصروفٌ على الصندوق: يأكل من ربح فترته ويخرج من خزينته.
  Future<Either<Failure, Unit>> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  });
}
