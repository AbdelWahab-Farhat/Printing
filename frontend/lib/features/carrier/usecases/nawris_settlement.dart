import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';

/// قرار كل طلبية في تقرير النورس. لا يغيّر شيئاً.
class PreviewNawrisSettlement {
  const PreviewNawrisSettlement(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisSettlementPreview>> call(PickedFile file) =>
      _repository.previewSettlement(path: file.path, fileName: file.name);
}

/// «تنفيذ» — يسوّي ما يصلح من التقرير ويتخطّى الباقي.
///
/// **المبلغ يُوحَّد هنا.** لوحة مفاتيح عربية تكتب `٣٨٠`، والخادم يقرأ `380`.
class ImportNawrisSettlement {
  const ImportNawrisSettlement(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisSettlementImport>> call(
    PickedFile file, {
    required String fingerprint,
    required String clientToken,
    String? receivedAmount,
    String? differenceReason,
    Map<String, String> accounts = const {},
    Set<int> leftOut = const {},
  }) {
    final reason = differenceReason?.trim() ?? '';

    return _repository.importSettlement(
      path: file.path,
      fileName: file.name,
      submission: NawrisSettlementSubmission(
        fingerprint: fingerprint,
        clientToken: clientToken,
        receivedAmount: receivedAmount == null
            ? null
            : Validators.toWesternDigits(receivedAmount.trim()),
        differenceReason: reason.isEmpty ? null : reason,
        accounts: accounts,
        leftOut: leftOut,
      ),
    );
  }
}

/// الدفعات السابقة.
class GetNawrisSettlementImports {
  const GetNawrisSettlementImports(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, Paginated<NawrisSettlementImport>>> call({required int page}) =>
      _repository.settlementImports(page: page);
}

/// دفعة بأسطرها.
class GetNawrisSettlementImport {
  const GetNawrisSettlementImport(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisSettlementImport>> call(int id) => _repository.settlementImport(id);
}

/// قالب الإدخال اليدوي.
class DownloadNawrisSettlementTemplate {
  const DownloadNawrisSettlementTemplate(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, Uint8List>> call() => _repository.settlementTemplate();
}
