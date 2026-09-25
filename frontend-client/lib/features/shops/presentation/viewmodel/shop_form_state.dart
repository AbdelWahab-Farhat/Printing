part of 'shop_form_cubit.dart';

/// كلُّ ما يمكن أن يكونه نموذج المتجر.
@freezed
sealed class ShopFormState with _$ShopFormState {
  const factory ShopFormState.loading() = ShopFormLoading;

  const factory ShopFormState.ready({
    /// كل المدن بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
    required List<City> cities,

    /// المجالات المعروضة، ومعها مجال المتجر إن أُوقف بعد تسجيله. فارغةٌ حين لم تصل، والحقل اختياري.
    @Default(<BusinessField>[]) List<BusinessField> businessFields,
    int? businessFieldId,
    int? cityId,
    int? regionId,
    @Default(false) bool isSaving,

    /// آخر حفظٍ رُفض. أخطاء الحقول تُعلَّق تحت حقولها، والباقي رسالة.
    Failure? lastFailure,
  }) = ShopFormReady;

  /// قائمة المدن لم تصل، والمتجر لا يُحفظ بلا مدينة.
  const factory ShopFormState.failure(Failure failure) = ShopFormFailure;
}

extension ShopFormStateX on ShopFormState {
  /// المدينة المختارة، تُقرأ من القائمة ولا تُخزَّن مرتين.
  City? get selectedCity => switch (this) {
    ShopFormReady(:final cities, :final cityId) => () {
      for (final city in cities) {
        if (city.id == cityId) return city;
      }

      return null;
    }(),
    _ => null,
  };

  /// المجال المختار، أو `null` لـ«غير محدد».
  BusinessField? get selectedBusinessField => switch (this) {
    ShopFormReady(:final businessFields, :final businessFieldId) => () {
      for (final field in businessFields) {
        if (field.id == businessFieldId) return field;
      }

      return null;
    }(),
    _ => null,
  };

  bool get isSaving => switch (this) {
    ShopFormReady(:final isSaving) => isSaving,
    _ => false,
  };

  /// هل يُرسل المتجر.
  ///
  /// **المنطقة مطلوبةٌ حيث تطلبها المدينة، وهذا أشدّ من الخادم عمداً.** الخادم يقبل متجراً بلا منطقة
  /// لأن الموظف على الهاتف قد لا يعرفها بعد. أما هنا فالمتجر وجهةُ طلبياتٍ قادمة، ومتجرٌ ناقص المنطقة
  /// في مدينةٍ تطلبها يوقف كلَّ طلبيةٍ إليه عند منتقي المنطقة.
  bool get canSave => switch (this) {
    ShopFormReady(:final cityId, :final regionId) =>
      cityId != null && (!(selectedCity?.needsRegion ?? false) || regionId != null),
    _ => false,
  };

  String? get nameError => _fieldError('name');

  String? get businessFieldError => _fieldError('business_field_id');

  String? get cityError => _fieldError('city_id');

  String? get regionError => _fieldError('region_id');

  String? get pageUrlError => _fieldError('page_url');

  /// رفضٌ لا حقلَ له في النموذج — انقطاع اتصال، أو خطأ خادم — فيُقال في رسالة بدل أن يضيع.
  bool get hasUnplacedFailure => switch (this) {
    ShopFormReady(lastFailure: _?) =>
      nameError == null &&
          businessFieldError == null &&
          cityError == null &&
          regionError == null &&
          pageUrlError == null,
    _ => false,
  };

  /// أخطاء الخادم لحقلٍ واحد، تُقرأ مرةً واحدة لا في خمس نسخٍ متشابهة.
  String? _fieldError(String field) => switch (this) {
    ShopFormReady(lastFailure: ServerFailure(:final fieldErrors)) =>
      fieldErrors?[field]?.firstOrNull,
    _ => null,
  };
}
