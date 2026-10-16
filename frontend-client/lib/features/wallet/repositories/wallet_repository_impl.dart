import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [WalletRepository] over HTTP.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, String>> balance() {
    return safeRequest<String>(
      () => _dio.get(WalletEndpoints.wallet),
      parse: (data) => ((data as Map<String, dynamic>)['balance'] ?? '0.00').toString(),
    );
  }

  @override
  Future<Either<Failure, Paginated<MyWalletEntry>>> entries({
    required int page,
    MyWalletFilter filter = MyWalletFilter.all,
  }) {
    return safePaginatedRequest<MyWalletEntry>(
      () => _dio.get(
        WalletEndpoints.entries,
        queryParameters: <String, dynamic>{'page': page, 'type': ?filter.wire},
      ),
      parseItem: MyWalletEntry.fromJson,
    );
  }

  @override
  Future<Either<Failure, String>> payOrder(int orderId, {String? amount, String? clientToken}) {
    return safeRequest<String>(
      () => _dio.post(
        WalletEndpoints.payOrder(orderId),
        data: <String, dynamic>{'amount': ?amount, 'client_token': ?clientToken},
      ),
      parse: (data) => ((data as Map<String, dynamic>)['balance'] ?? '0.00').toString(),
    );
  }
}
