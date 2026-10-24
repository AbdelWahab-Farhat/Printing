import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dio/dio.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, CustomerWallet>> wallet(int customerId) {
    return safeRequest<CustomerWallet>(
      () => _dio.get(WalletEndpoints.customerWallet(customerId)),
      parse: (data) => CustomerWallet.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<CustomerWalletEntry>>> entries({
    int? customerId,
    required int page,
    int? perPage,
    WalletEntryFilter filter = WalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  }) {
    return safePaginatedRequest<CustomerWalletEntry>(
      () => _dio.get(
        customerId == null ? WalletEndpoints.entries : WalletEndpoints.customerEntries(customerId),
        // المفاتيح الفارغة تُحذف ولا تُرسل — RULES §٦.
        queryParameters: {
          'page': page,
          'per_page': ?perPage,
          'type': ?filter.wire,
          if (customerId == null) 'q': ?search,
          // أيامُ المحلّ: الخادم يقرأ اليوم بتوقيت طرابلس.
          if (from != null) 'from': _day(from),
          if (to != null) 'to': _day(to),
        },
      ),
      parseItem: CustomerWalletEntry.fromJson,
    );
  }

  static String _day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  @override
  Future<Either<Failure, WalletWrite>> topUp(
    int customerId, {
    required String amount,
    required TopUpMethod method,
    int? treasuryAccountId,
    String? reference,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) {
    return safeRequest<WalletWrite>(
      () async => _dio.post(
        WalletEndpoints.topUp(customerId),
        // Multipart, like an order payment: a transfer carries its receipt.
        data: FormData.fromMap(<String, dynamic>{
          'amount': amount,
          'method': method.wire,
          'treasury_account_id': ?treasuryAccountId,
          if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (receiptPath != null)
            'receipt': await LocalFiles.multipart(receiptPath, filename: receiptFilename ?? 'receipt'),
        }),
      ),
      parse: (data) => WalletWrite.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, WalletWrite>> adjust(
    int customerId, {
    required String amount,
    required bool credit,
    required String reason,
  }) {
    return safeRequest<WalletWrite>(
      () => _dio.post(
        WalletEndpoints.adjust(customerId),
        data: <String, dynamic>{
          'direction': credit ? 'credit' : 'debit',
          'amount': amount,
          'reason': reason.trim(),
        },
      ),
      parse: (data) => WalletWrite.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, WalletWrite>> reverse(int entryId, {required String reason}) {
    return safeRequest<WalletWrite>(
      () => _dio.post(WalletEndpoints.reverse(entryId), data: <String, dynamic>{'reason': reason.trim()}),
      parse: (data) => WalletWrite.fromJson(data as Map<String, dynamic>),
    );
  }
}
