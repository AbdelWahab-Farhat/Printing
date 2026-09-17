import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [BadgeRepository] over HTTP.
class BadgeRepositoryImpl implements BadgeRepository {
  const BadgeRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() {
    return safeRequest<Map<CustomerBadge, int>>(
      () => _dio.get(BadgeEndpoints.index),
      parse: (data) {
        final counts = <CustomerBadge, int>{};

        (data as Map<String, dynamic>).forEach((key, value) {
          // **A key this build does not know is skipped, not an error.** The server may grow a
          // badge before the app does, and an older build must keep drawing the ones it knows
          // rather than failing the whole call over a word it has never seen.
          final badge = CustomerBadge.fromWire(key);

          if (badge != null) counts[badge] = (value as num?)?.toInt() ?? 0;
        });

        return counts;
      },
    );
  }
}
