import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/usecases/add_shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_business_fields.dart';
import 'package:dayaa_client/features/shops/usecases/update_shop.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_form_cubit.freezed.dart';
part 'shop_form_state.dart';

/// الـ ViewModel لنموذج المتجر — إضافةً وتعديلاً، و[editing] هو ما يقرّر الفعل.
///
/// **بحقول نموذج الموظفين الأربعة:** الاسم، ومجال العمل، والمدينة والمنطقة، ورابط الصفحة. ويملك
/// الاختيارات لا الكتابة، كما في السلة: المجال والمدينة والمنطقة هنا، والاسم والرابط في متحكّمَي
/// الشاشة ويصلان عند [save].
class ShopFormCubit extends Cubit<ShopFormState> {
  ShopFormCubit({
    required ListCities cities,
    required ListBusinessFields businessFields,
    required AddShop add,
    required UpdateShop update,
    this.editing,
  }) : _cities = cities,
       _businessFields = businessFields,
       _add = add,
       _update = update,
       super(const ShopFormState.loading());

  final ListCities _cities;
  final ListBusinessFields _businessFields;
  final AddShop _add;
  final UpdateShop _update;

  /// المتجر الذي يُعدَّل، أو `null` لمتجرٍ جديد.
  final Shop? editing;

  Future<void> load() async {
    emit(const ShopFormState.loading());

    // يبدآن معاً: قائمتان لنموذجٍ واحد.
    final citiesResult = _cities();
    final fieldsResult = _businessFields();

    final cities = await citiesResult;

    // **المجالات لا توقف النموذج.** الحقل اختياري، ونموذجٌ رُفض لأن قائمةً اختيارية تأخّرت هو
    // التطبيق يخترع قاعدة.
    final offered = (await fieldsResult).fold((_) => const <BusinessField>[], (list) => list);

    if (isClosed) return;

    emit(
      cities.fold(
        // متجرٌ بلا مدينة لا يُحفظ، فقائمة مدنٍ لم تصل نموذجٌ لا يُكمَل.
        (failure) => ShopFormState.failure(failure),
        (cities) {
          final shop = editing;

          // **يُختار ما زال على الخريطة وحده.** مدينةٌ أُخرجت منها بعد تسجيل المتجر لا تطابق شيئاً
          // في المنتقي فيرسمه فارغاً، فالأصدق أن تبدأ فارغةً ويُطلب اختيارها.
          final city = _cityIn(cities, shop?.cityId);
          final regionId = shop?.regionId;
          final hasRegion = city?.regions.any((region) => region.id == regionId) ?? false;

          return ShopFormState.ready(
            cities: cities,
            businessFields: _withCurrent(offered, shop?.businessField),
            businessFieldId: shop?.businessFieldId,
            cityId: city?.id,
            regionId: hasRegion ? regionId : null,
          );
        },
      ),
    );
  }

  /// **يمسح المنطقة**: المنطقة تخصّ المدينة التي اختيرت فيها.
  void chooseCity(int cityId) {
    final ready = _ready;
    if (ready == null || ready.cityId == cityId) return;

    emit(ready.copyWith(cityId: cityId, regionId: null, lastFailure: null));
  }

  void chooseRegion(int? regionId) {
    final ready = _ready;
    if (ready == null) return;

    emit(ready.copyWith(regionId: regionId, lastFailure: null));
  }

  /// `null` هو «غير محدد»، وذلك جوابٌ حقيقي.
  void chooseBusinessField(int? businessFieldId) {
    final ready = _ready;
    if (ready == null) return;

    emit(ready.copyWith(businessFieldId: businessFieldId, lastFailure: null));
  }

  /// يحفظ المتجر ويعيده كما قبله الخادم، لتضعه الشاشة التي فتحت النموذج في مكانه.
  ///
  /// `null` يعني أنه لم يُحفظ، و`lastFailure` يقول لماذا.
  Future<Shop?> save({required String name, String? pageUrl}) async {
    final ready = _ready;
    final cityId = ready?.cityId;
    if (ready == null || ready.isSaving || !ready.canSave || cityId == null) return null;

    emit(ready.copyWith(isSaving: true, lastFailure: null));

    // المسافات ليست اسماً ولا رابطاً، والخانة الفارغة «لا رابط» لا نصٌّ فارغ يرفضه الخادم.
    final cleanName = name.trim();
    final link = pageUrl?.trim();
    final cleanLink = (link == null || link.isEmpty) ? null : link;

    final shop = editing;
    final result = shop == null
        ? await _add(
            name: cleanName,
            cityId: cityId,
            regionId: ready.regionId,
            businessFieldId: ready.businessFieldId,
            pageUrl: cleanLink,
          )
        : await _update(
            id: shop.id,
            name: cleanName,
            cityId: cityId,
            regionId: ready.regionId,
            businessFieldId: ready.businessFieldId,
            pageUrl: cleanLink,
          );

    if (isClosed) return result.fold((_) => null, (saved) => saved);

    final current = _ready ?? ready;

    return result.fold(
      (failure) {
        emit(current.copyWith(isSaving: false, lastFailure: failure));

        return null;
      },
      (saved) {
        emit(current.copyWith(isSaving: false));

        return saved;
      },
    );
  }

  /// المجالات المعروضة، ومعها مجال المتجر إن لم يكن بينها — كما في منتقي الموظفين: فتحُ متجرٍ قديم
  /// لا يمحو مجالاً سُجّل له يوماً ثم أُوقف.
  static List<BusinessField> _withCurrent(List<BusinessField> offered, BusinessField? current) {
    if (current == null || offered.any((field) => field.id == current.id)) return offered;

    return [...offered, current];
  }

  static City? _cityIn(List<City> cities, int? cityId) {
    for (final city in cities) {
      if (city.id == cityId) return city;
    }

    return null;
  }

  ShopFormReady? get _ready => switch (state) {
    final ShopFormReady ready => ready,
    _ => null,
  };
}
