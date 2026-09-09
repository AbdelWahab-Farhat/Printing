import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';

/// The figures the business is read by, stated without saying where they come from.
///
/// Two methods, and neither is paginated: a report is a single object about a whole period, so
/// there is no page to ask for and no `Paginated` to unwrap.
///
/// **They answer to two different permissions**, which is why they are two methods rather than
/// one call with a mode: `reports.pnl.view` opens the first, `reports.sales.view` the second, and
/// a person may hold either without the other.
abstract interface class ReportRepository {
  /// Revenue against cost of goods sold between two days, both ends included.
  ///
  /// Both dates are required by the server, so neither is nullable and there is nothing here to
  /// omit — unlike every list in this app, this call has no optional filter.
  Future<Either<Failure, ProfitAndLossSummary>> profitAndLoss({
    required String from,
    required String to,
  });

  /// حجم المبيعات وحركة الأكياس between the same two days, on the same terms.
  ///
  /// Bags only: everything دعاية sells through a vendor is left off the board entirely, by the
  /// server, and there is no filter here that would put it back.
  Future<Either<Failure, SalesStatistics>> salesStatistics({
    required String from,
    required String to,
  });
}
