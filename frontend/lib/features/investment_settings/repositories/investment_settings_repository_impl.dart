import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';
import 'package:dayaa/features/investment_settings/repositories/investment_settings_repository.dart';
import 'package:dio/dio.dart';

class InvestmentSettingsRepositoryImpl implements InvestmentSettingsRepository {
  const InvestmentSettingsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, InvestmentSettings>> settings() {
    return safeRequest<InvestmentSettings>(
      () => _dio.get(SettingsEndpoints.settings),
      parse: (data) => InvestmentSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestmentSettings>> update(InvestmentSettings settings) {
    return safeRequest<InvestmentSettings>(
      () => _dio.put(SettingsEndpoints.settings, data: settings.toJson()),
      parse: (data) => InvestmentSettings.fromJson(data as Map<String, dynamic>),
    );
  }
}
