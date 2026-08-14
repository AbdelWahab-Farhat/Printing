import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';

/// الأرباح والخسائر between two days.
///
/// **It normalises nothing, and that is the rule it carries.** Every other use case in this app
/// trims a name or turns `٢٥` into `25`; here both values come from a date picker, so there is
/// no keyboard to correct for — and the one thing a client could be tempted to "fix", a `to`
/// that falls before `from`, is left to the server on purpose. It answers «تاريخ النهاية يجب أن
/// يكون بعد تاريخ البداية» under the right field, and re-implementing that check here would mean
/// this app inventing its own Arabic for a rule it does not own.
class GetProfitAndLoss {
  const GetProfitAndLoss(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, ProfitAndLossSummary>> call({
    required String from,
    required String to,
  }) => _repository.profitAndLoss(from: from, to: to);
}
