import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';

/// إحصائيات المبيعات between two days.
///
/// **It normalises nothing**, and it carries that rule for the same reason [GetProfitAndLoss]
/// does: both values come from a picker or a preset, so there is no keyboard to correct for —
/// and the one thing a client could be tempted to "fix", a `to` that falls before `from`, is left
/// to the server on purpose. It answers «تاريخ النهاية يجب أن يكون بعد تاريخ البداية» under the
/// right field, and re-implementing that check here would mean this app inventing its own Arabic
/// for a rule it does not own.
class GetSalesStatistics {
  const GetSalesStatistics(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, SalesStatistics>> call({
    required String from,
    required String to,
  }) => _repository.salesStatistics(from: from, to: to);
}
