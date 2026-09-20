import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/company_settings/models/company_settings.dart';
import 'package:dayaa/features/company_settings/repositories/company_settings_repository.dart';

class GetCompanySettings {
  const GetCompanySettings(this._repository);

  final CompanySettingsRepository _repository;

  Future<Either<Failure, CompanySettings>> call() => _repository.settings();
}

class UpdateCompanySettings {
  const UpdateCompanySettings(this._repository);

  final CompanySettingsRepository _repository;

  Future<Either<Failure, CompanySettings>> call(CompanySettings settings) =>
      _repository.update(settings);
}
