import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dio/dio.dart';

class EmployeeWalletRepositoryImpl implements EmployeeWalletRepository {
  const EmployeeWalletRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, EmployeeWallet>> wallet(int userId) =>
      _read(EmployeeWalletEndpoints.wallet(userId));

  @override
  Future<Either<Failure, EmployeeWallet>> myWallet() => _read(EmployeeWalletEndpoints.myWallet);

  Future<Either<Failure, EmployeeWallet>> _read(String path) {
    return safeRequest<EmployeeWallet>(
      () => _dio.get(path),
      parse: (data) => EmployeeWallet.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<EmployeeWalletEntry>>> entries(
    EmployeeWalletLedger ledger, {
    required int page,
    EmployeeWalletEntryFilter filter = EmployeeWalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  }) {
    return safePaginatedRequest<EmployeeWalletEntry>(
      () => _dio.get(
        switch (ledger) {
          EmployeeWalletLedgerOf(:final userId) => EmployeeWalletEndpoints.entries(userId),
          EmployeeWalletLedgerAll() => EmployeeWalletEndpoints.allEntries,
          EmployeeWalletLedgerMine() => EmployeeWalletEndpoints.myEntries,
        },
        // المفاتيح الفارغة تُحذف ولا تُرسل — RULES §٦.
        queryParameters: {
          'page': page,
          'type': ?filter.wire,
          if (ledger is EmployeeWalletLedgerAll) 'q': ?search,
          // أيامُ المحلّ: الخادم يقرأ اليوم بتوقيت طرابلس.
          if (from != null) 'from': _day(from),
          if (to != null) 'to': _day(to),
        },
      ),
      parseItem: EmployeeWalletEntry.fromJson,
    );
  }

  static String _day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  @override
  Future<Either<Failure, EmployeeWalletWrite>> deposit(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _money(EmployeeWalletEndpoints.deposits(userId), draft, clientToken);

  @override
  Future<Either<Failure, EmployeeWalletWrite>> withdraw(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _money(EmployeeWalletEndpoints.withdrawals(userId), draft, clientToken);

  /// الحقول نفسها في الاتجاهين، و**multipart** لأن الحوالة تحمل واصلها.
  Future<Either<Failure, EmployeeWalletWrite>> _money(
    String path,
    EmployeeMoneyDraft draft,
    String clientToken,
  ) {
    return safeRequest<EmployeeWalletWrite>(
      () async => _dio.post(
        path,
        data: FormData.fromMap(<String, dynamic>{
          'amount': draft.amount,
          'method': draft.method.wire,
          'client_token': clientToken,
          'treasury_account_id': ?draft.treasuryAccountId,
          'reference': ?_filled(draft.reference),
          'notes': ?_filled(draft.notes),
          if (draft.receiptPath case final receipt?)
            'receipt': await LocalFiles.multipart(
              receipt,
              filename: draft.receiptFilename ?? 'receipt',
            ),
        }),
      ),
      parse: _write,
    );
  }

  @override
  Future<Either<Failure, EmployeeWalletWrite>> credit(
    int userId,
    EmployeeCreditDraft draft, {
    required String clientToken,
  }) {
    return safeRequest<EmployeeWalletWrite>(
      () => _dio.post(
        EmployeeWalletEndpoints.credits(userId),
        data: <String, dynamic>{
          'amount': draft.amount,
          'category_id': draft.categoryId,
          'notes': ?_filled(draft.notes),
          'client_token': clientToken,
        },
      ),
      parse: _write,
    );
  }

  @override
  Future<Either<Failure, EmployeeWalletWrite>> adjust(
    int userId, {
    required String amount,
    required bool credit,
    required String reason,
    required String clientToken,
  }) {
    return safeRequest<EmployeeWalletWrite>(
      () => _dio.post(
        EmployeeWalletEndpoints.adjustments(userId),
        data: <String, dynamic>{
          'direction': credit ? 'credit' : 'debit',
          'amount': amount,
          'reason': reason.trim(),
          'client_token': clientToken,
        },
      ),
      parse: _write,
    );
  }

  @override
  Future<Either<Failure, EmployeeWalletWrite>> reverse(int entryId, {required String reason}) {
    return safeRequest<EmployeeWalletWrite>(
      () => _dio.post(
        EmployeeWalletEndpoints.reverse(entryId),
        data: <String, dynamic>{'reason': reason.trim()},
      ),
      parse: _write,
    );
  }

  static EmployeeWalletWrite _write(Object? data) =>
      EmployeeWalletWrite.fromJson(data as Map<String, dynamic>);

  /// النصُّ مقصوصاً، أو null حين لا شيء فيه — فلا يُرسل مفتاحٌ فارغ.
  static String? _filled(String? text) {
    final trimmed = text?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
