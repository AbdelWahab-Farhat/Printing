import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/home/models/home_summary.dart';

/// What the home screen needs, stated without saying where it comes from.
///
/// The contract is worth having even while the numbers are still stand-ins: the Cubit and its
/// test depend on *this*, so the day the endpoint lands, the only file that changes is the
/// implementation — not the ViewModel, not the screen, and not a single test.
abstract interface class HomeRepository {
  /// The counts and the status breakdown, as one snapshot.
  Future<Either<Failure, HomeSummary>> summary();
}
