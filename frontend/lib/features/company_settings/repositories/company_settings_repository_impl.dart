import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/company_settings/models/company_settings.dart';
import 'package:dayaa/features/company_settings/repositories/company_settings_repository.dart';
import 'package:dio/dio.dart';

class CompanySettingsRepositoryImpl implements CompanySettingsRepository {
  const CompanySettingsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, CompanySettings>> settings() {
    return safeRequest<CompanySettings>(
      () => _dio.get(CompanySettingsEndpoints.settings),
      parse: (data) => CompanySettings.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CompanySettings>> update(CompanySettings settings) {
    return safeRequest<CompanySettings>(
      // Every field, every time. The server validates the four together — a partial body would
      // be refused, and sending one anyway is how a screen comes to show a value nobody saved.
      () => _dio.put(
        CompanySettingsEndpoints.settings,
        data: <String, dynamic>{
          'investor_profit_share_percent': settings.investorProfitSharePercent,
          'profit_period_months': settings.profitPeriodMonths,
          'settlement_period_months': settings.settlementPeriodMonths,
          'entry_grace_days': settings.entryGraceDays,
          'minimum_term_months': settings.minimumTermMonths,
        },
      ),
      parse: (data) => CompanySettings.fromJson(data as Map<String, dynamic>),
    );
  }
}
