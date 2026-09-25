part of 'billboard_cubit.dart';

/// كل ما يمكن أن يكونه الشريط.
@freezed
sealed class BillboardState with _$BillboardState {
  const factory BillboardState.loading() = BillboardLoading;

  /// **قائمةٌ فارغة جوابٌ صحيح لا فشل**: المتجر لا يعرض حملةً الآن، فيملأ التطبيق الشريط
  /// بإعلاناته هو ([showsHouseAds]).
  const factory BillboardState.loaded(List<Billboard> billboards) = BillboardLoaded;

  const factory BillboardState.failure(Failure failure) = BillboardFailure;
}

extension BillboardStateX on BillboardState {
  /// هل يعرض المتجر شيئاً من عنده؟
  bool get hasAnything => switch (this) {
    BillboardLoaded(:final billboards) => billboards.isNotEmpty,
    _ => false,
  };

  List<Billboard> get billboards => switch (this) {
    BillboardLoaded(:final billboards) => billboards,
    _ => const <Billboard>[],
  };

  /// هل يملأ التطبيق الشريط بإعلاناته هو؟ نعم حين لا يعرض المتجر شيئاً: لا حملة جارية، أو
  /// شريطٌ لم يُحمَّل. **ولا أثناء التحميل**، كي لا يومض إعلانٌ من التطبيق ثم يختفي تحت إعلانٍ
  /// حقيقي بعد لحظة.
  bool get showsHouseAds => switch (this) {
    BillboardLoading() => false,
    BillboardLoaded(:final billboards) => billboards.isEmpty,
    BillboardFailure() => true,
  };
}
