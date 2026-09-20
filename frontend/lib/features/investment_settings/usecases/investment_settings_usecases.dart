import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';
import 'package:dayaa/features/investment_settings/repositories/investment_settings_repository.dart';

class GetInvestmentSettings {
  const GetInvestmentSettings(this._repository);

  final InvestmentSettingsRepository _repository;

  Future<Either<Failure, InvestmentSettings>> call() => _repository.settings();
}

class UpdateInvestmentSettings {
  const UpdateInvestmentSettings(this._repository);

  final InvestmentSettingsRepository _repository;

  Future<Either<Failure, InvestmentSettings>> call(InvestmentSettings settings) =>
      _repository.update(settings);
}
