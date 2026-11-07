import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/usecases/nawris_settlement.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nawris_settlement_cubit.freezed.dart';

/// خطوات الشاشة: اختيار الملف، ثم المعاينة، ثم التنفيذ.
@freezed
sealed class NawrisSettlementState with _$NawrisSettlementState {
  const factory NawrisSettlementState.idle() = NawrisSettlementIdle;

  const factory NawrisSettlementState.reading(PickedFile file) = NawrisSettlementReading;

  /// لم يُقرأ الملف، أو رفضه الخادم. لا معاينة لتُعرض.
  const factory NawrisSettlementState.unreadable(Failure failure) = NawrisSettlementUnreadable;

  const factory NawrisSettlementState.ready({
    required PickedFile file,
    required NawrisSettlementPreview preview,
  }) = NawrisSettlementReady;

  const factory NawrisSettlementState.submitting({
    required PickedFile file,
    required NawrisSettlementPreview preview,
  }) = NawrisSettlementSubmitting;

  /// رُفض التنفيذ ولم يتغيّر شيء. المعاينة باقية وما كتبه الموظف معها.
  const factory NawrisSettlementState.refused({
    required PickedFile file,
    required NawrisSettlementPreview preview,
    required Failure failure,
  }) = NawrisSettlementRefused;

  const factory NawrisSettlementState.settled(NawrisSettlementImport batch) =
      NawrisSettlementSettled;
}

/// تقرير النورس من الملف إلى الدفعة.
///
/// **رمز واحد لكل معاينة** ([_token]): الإعادة بعد انقطاع ترسل الرمز نفسه، فإن كان الطلب الأول قد
/// وصل أعاد الخادم الدفعة نفسها ولم يسوِّ مرتين. وكل معاينة جديدة رمزٌ جديد، لأنها قرار جديد.
class NawrisSettlementCubit extends Cubit<NawrisSettlementState> {
  NawrisSettlementCubit({
    required PreviewNawrisSettlement preview,
    required ImportNawrisSettlement import,
    String Function()? newToken,
  }) : _preview = preview,
       _import = import,
       _newToken = newToken ?? uuidV4,
       super(const NawrisSettlementState.idle());

  final PreviewNawrisSettlement _preview;
  final ImportNawrisSettlement _import;
  final String Function() _newToken;

  String _token = '';

  Future<void> read(PickedFile file) async {
    emit(NawrisSettlementState.reading(file));

    final result = await _preview(file);

    if (isClosed) return;

    _token = _newToken();

    emit(
      result.fold(
        (failure) => NawrisSettlementState.unreadable(failure),
        (preview) => NawrisSettlementState.ready(file: file, preview: preview),
      ),
    );
  }

  /// بعد رفضٍ لأن الطلبيات تغيّرت: الملف نفسه، بما صار عليه النظام الآن.
  Future<void> readAgain() async {
    if (state case NawrisSettlementRefused(:final file)) {
      await read(file);
    }
  }

  Future<void> submit({
    String? receivedAmount,
    String? differenceReason,
    Map<String, String> accounts = const {},
    Set<int> leftOut = const {},
  }) async {
    final (file, preview) = switch (state) {
      NawrisSettlementReady(:final file, :final preview) => (file, preview),
      NawrisSettlementRefused(:final file, :final preview) => (file, preview),
      _ => (null, null),
    };

    if (file == null || preview == null) return;

    emit(NawrisSettlementState.submitting(file: file, preview: preview));

    final result = await _import(
      file,
      fingerprint: preview.fingerprint,
      clientToken: _token,
      receivedAmount: preview.holdsMoney(leftOut) ? receivedAmount : null,
      differenceReason: differenceReason,
      accounts: accounts,
      leftOut: leftOut,
    );

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => NawrisSettlementState.refused(file: file, preview: preview, failure: failure),
        (batch) => NawrisSettlementState.settled(batch),
      ),
    );
  }

  /// ملف آخر، أو إلغاء المعاينة. لا شيء تغيّر حتى يُضغط «تنفيذ».
  void reset() => emit(const NawrisSettlementState.idle());
}
