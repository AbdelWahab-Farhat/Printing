import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';

/// The figures the business is read by, stated without saying where they come from.
///
/// One method so far, and it is deliberately not paginated: the report is a single object about
/// a whole period, so there is no page to ask for and no `Paginated` to unwrap.
abstract interface class ReportRepository {
  /// Revenue against cost of goods sold between two days, both ends included.
  ///
  /// Both dates are required by the server, so neither is nullable and there is nothing here to
  /// omit — unlike every list in this app, this call has no optional filter.
  Future<Either<Failure, ProfitAndLossSummary>> profitAndLoss({
    required String from,
    required String to,
  });
}
