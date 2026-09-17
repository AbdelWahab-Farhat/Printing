import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';

/// What the shop is showing right now.
abstract interface class BillboardRepository {
  /// In the order staff arranged it.
  ///
  /// **Never paged, and never filtered here.** A carousel is a handful of pictures, and the
  /// schedule is applied on the server — a banner whose window has closed never leaves it, so
  /// there is no date for this app to compare against a clock it does not control.
  Future<Either<Failure, List<Billboard>>> showing();
}
