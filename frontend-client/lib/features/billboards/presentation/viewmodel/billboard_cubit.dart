import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billboard_cubit.freezed.dart';
part 'billboard_state.dart';

/// الـ ViewModel لشريط الإعلانات أعلى الرئيسية.
///
/// **إعلانٌ لم يُحمَّل ليس خطأً يُعرض على العميل.** الشريط الذي فشل تملؤه إعلانات التطبيق
/// نفسه (`HouseAd`)، و[BillboardState.failure] موجودةٌ كي تُعاد المحاولة *بصمت*، لا صندوقاً
/// أحمر على أول ما يراه من يفتح التطبيق.
class BillboardCubit extends Cubit<BillboardState> {
  BillboardCubit({required GetBillboards get})
    : _get = get,
      super(const BillboardState.loading());

  final GetBillboards _get;

  /// **التحميل الأول وحده يمرّ بـ [BillboardState.loading].** السحب للتحديث يُبقي ما يعرضه
  /// الشريط حتى يصل الجواب الجديد، وإن فشل بقي كما هو: شريطٌ ينطفئ ويعود مع كل سحبةٍ وميضٌ بلا
  /// معنى، وإعلانٌ عُرض قبل دقيقة أصدق من فراغٍ مكانه.
  Future<void> load() async {
    final wasShowing = state is BillboardLoaded;

    if (!wasShowing) emit(const BillboardState.loading());

    final result = await _get();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!wasShowing) emit(BillboardState.failure(failure));
      },
      (billboards) => emit(BillboardState.loaded(billboards)),
    );
  }
}
