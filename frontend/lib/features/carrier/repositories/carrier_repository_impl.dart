import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/carrier/models/carrier_money_sync.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [CarrierRepository] over HTTP.
class CarrierRepositoryImpl implements CarrierRepository {
  const CarrierRepositoryImpl(this._dio);

  final Dio _dio;

  /// تسوية مئات الطلبيات تأخذ أكثر مما تُضبط عليه مهلة صفحة JSON، وانقطاعٌ هنا يُظهر فشلاً لعملية
  /// قد تكون نجحت — ومع أن الرمز يحمي من التكرار، فالانتظار أصدق من إعادة المحاولة.
  static const Duration _settlementTimeout = Duration(minutes: 5);

  @override
  Future<Either<Failure, NawrisSettlementPreview>> previewSettlement({
    required String path,
    required String fileName,
  }) {
    return safeRequest<NawrisSettlementPreview>(
      () async => _dio.post(
        CarrierEndpoints.settlementImportPreview,
        data: FormData.fromMap(<String, dynamic>{
          'file': await LocalFiles.multipart(path, filename: fileName),
        }),
        options: Options(receiveTimeout: _settlementTimeout),
      ),
      parse: (data) => NawrisSettlementPreview.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, NawrisSettlementImport>> importSettlement({
    required String path,
    required String fileName,
    required NawrisSettlementSubmission submission,
  }) {
    return safeRequest<NawrisSettlementImport>(
      () async => _dio.post(
        CarrierEndpoints.settlementImports,
        data: FormData.fromMap(<String, dynamic>{
          'file': await LocalFiles.multipart(path, filename: fileName),
          'fingerprint': submission.fingerprint,
          'client_token': submission.clientToken,
          'received_amount': ?submission.receivedAmount,
          'difference_reason': ?submission.differenceReason,
          for (final account in submission.accounts.entries)
            'fields[${account.key}]': account.value,
          for (final (index, orderId) in submission.leftOut.indexed)
            'left_out[$index]': orderId.toString(),
        }),
        options: Options(receiveTimeout: _settlementTimeout),
      ),
      parse: (data) => NawrisSettlementImport.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<NawrisSettlementImport>>> settlementImports({
    required int page,
  }) {
    return safePaginatedRequest<NawrisSettlementImport>(
      () => _dio.get(CarrierEndpoints.settlementImports, queryParameters: {'page': page}),
      parseItem: NawrisSettlementImport.fromJson,
    );
  }

  @override
  Future<Either<Failure, NawrisSettlementImport>> settlementImport(int id) {
    return safeRequest<NawrisSettlementImport>(
      () => _dio.get(CarrierEndpoints.settlementImport(id)),
      parse: (data) => NawrisSettlementImport.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Uint8List>> settlementTemplate() {
    return safeDownload(
      () => _dio.get<List<int>>(
        CarrierEndpoints.settlementImportTemplate,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
  }

  @override
  Future<Either<Failure, NawrisParcel>> lodge(int orderId) {
    return safeRequest<NawrisParcel>(
      () => _dio.post(CarrierEndpoints.lodge(orderId)),
      parse: (data) => NawrisParcel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, NawrisParcel>> lodgeTogether(List<int> orderIds) {
    return safeRequest<NawrisParcel>(
      () => _dio.post(CarrierEndpoints.sharedParcel, data: {'order_ids': orderIds}),
      parse: (data) => NawrisParcel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, NawrisParcel?>> resend(int orderId) =>
      _letGo(CarrierEndpoints.resend(orderId));

  @override
  Future<Either<Failure, NawrisParcel?>> deleteShipment(int orderId) =>
      _letGo(CarrierEndpoints.deleteShipment(orderId));

  @override
  Future<Either<Failure, NawrisParcel?>> unlink(int orderId) =>
      _letGo(CarrierEndpoints.unlink(orderId));

  @override
  Future<Either<Failure, CarrierMoneySync?>> syncMoney(int orderId) {
    return safeRequest<CarrierMoneySync?>(
      () => _dio.post(CarrierEndpoints.syncMoney(orderId)),
      // `data: null` is «لا توجد شحنة مفتوحة» — an answer, like [_letGo]'s.
      parse: (data) => data == null
          ? null
          : CarrierMoneySync.fromJson(data as Map<String, dynamic>),
    );
  }

  /// The three that answer with a parcel **or** with nothing.
  ///
  /// An order with no open parcel comes back as a success carrying `data: null` — «لا توجد شحنة
  /// مفتوحة» — so a parser that insisted on a map would turn the server's polite answer into a
  /// crash. Re-sending shares the shape even though it *creates* rather than releases: the same
  /// "nothing out" answer applies, and the parcel it hands back is a new one either way.
  Future<Either<Failure, NawrisParcel?>> _letGo(String endpoint) {
    return safeRequest<NawrisParcel?>(
      () => _dio.post(endpoint),
      parse: (data) => data == null
          ? null
          : NawrisParcel.fromJson(data as Map<String, dynamic>),
    );
  }
}
