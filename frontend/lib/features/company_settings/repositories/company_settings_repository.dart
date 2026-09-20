import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/company_settings/models/company_settings.dart';

/// The company's editable defaults — one row, read and written whole.
///
/// **Whole, not field by field.** The four numbers are read together on one screen and saved
/// together by one button, and a per-field endpoint would let a client save three of them and
/// leave the fourth showing a value the server never took.
abstract class CompanySettingsRepository {
  Future<Either<Failure, CompanySettings>> settings();

  Future<Either<Failure, CompanySettings>> update(CompanySettings settings);
}
