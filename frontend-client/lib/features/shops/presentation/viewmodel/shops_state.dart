part of 'shops_cubit.dart';

/// كلُّ ما يمكن أن تكونه «متاجري».
///
/// **`isBusy` و`lastFailure` على الحالة المحمَّلة لا بدلاً منها**، كما في «تصاميمي»: حذفٌ فشل لا
/// يأخذ القائمة معه.
@freezed
sealed class ShopsState with _$ShopsState {
  const factory ShopsState.loading() = ShopsLoading;

  const factory ShopsState.loaded(
    List<Shop> shops, {

    /// حذفٌ في الطريق: القائمة باقية، والأزرار مقفلة.
    @Default(false) bool isBusy,

    /// آخر حذفٍ فشل، ويُمسح مع الحالة التالية.
    Failure? lastFailure,
  }) = ShopsLoaded;

  /// التحميل *الأول* وحده — بعده توجد قائمةٌ تبقى معروضة.
  const factory ShopsState.failure(Failure failure) = ShopsFailure;
}
