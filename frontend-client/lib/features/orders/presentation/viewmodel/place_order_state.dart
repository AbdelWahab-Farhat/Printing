part of 'place_order_cubit.dart';

/// خطوتا السلة، بالترتيب الذي يرسمه الشريط أعلاها.
enum CheckoutStep {
  /// «المنتجات» — ما في السلة، ويُحذف منه.
  products,

  /// «بيانات الطلب» — المتجر والوجهة وهاتف الاستلام والتصاميم والملاحظة.
  details,
}

/// تسعير السلة من الخادم: لم يصل بعد، أو وصل، أو فشل.
///
/// **الفشل لا يوقف الطلبية.** الرقم معلومةٌ للعميل لا شرطٌ للإرسال — المتجر يسعّر الطلبية حين تصله
/// في كل حال — فسلةٌ تعذّر تسعيرها تُرسل كما تُرسل غيرها، وتقول إن التكلفة لم تُحسب.
@freezed
sealed class BasketPricing with _$BasketPricing {
  const factory BasketPricing.pending() = BasketPricingPending;

  const factory BasketPricing.priced(BasketQuote quote) = BasketPriced;

  const factory BasketPricing.failed(Failure failure) = BasketPricingFailed;
}

/// كلُّ ما يمكن أن تكونه شاشة السلة.
@freezed
sealed class PlaceOrderState with _$PlaceOrderState {
  const factory PlaceOrderState.loading() = PlaceOrderLoading;

  const factory PlaceOrderState.ready({
    /// كل الوجهات بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
    required List<City> cities,

    /// مكتبة العميل لإرفاق التصاميم. **الفارغة مقبولة**: الإرفاق اختياري، والمكتبة التي فشل
    /// تحميلها تبدو هكذا أيضاً، ولا يستحق أيٌّ منهما رفضَ طلبية.
    @Default(<CustomerDesign>[]) List<CustomerDesign> designs,

    /// متاجر العميل بترتيب إضافتها — ومنها تُختار الوجهة.
    @Default(<Shop>[]) List<Shop> shops,

    @Default(<OrderDraftLine>[]) List<OrderDraftLine> lines,

    @Default(CheckoutStep.products) CheckoutStep step,

    /// المتجر الذي تذهب إليه البضاعة. اختياريٌّ عند الخادم، ويُختار أولُ المتاجر عند الفتح.
    int? shopId,
    int? cityId,
    int? regionId,
    @Default(<int>[]) List<int> designIds,

    /// رقم الحساب، يُملأ به حقل «هاتف الاستلام» مرةً عند الفتح ثم يبقى الحقل للعميل. `null` حين
    /// لم تصل قراءة الحساب — فيكتبه العميل، ولا يتوقف شيء.
    String? customerPhone,

    /// سعر كل سطرٍ والتكلفة النهائية، كما حسبها الخادم للسطور والمدينة الحاليّتين.
    @Default(BasketPricing.pending()) BasketPricing pricing,

    @Default(false) bool isSubmitting,

    /// الطلبية التي أنشأها المتجر. **«بانتظار المراجعة»** — لا شيء مؤكَّد ولا شيء مُسعَّر من المخزن
    /// قبل أن يقرأها أحد.
    CustomerOrderDetail? placed,

    Failure? lastFailure,
  }) = PlaceOrderReady;

  /// المنتقي أو المتاجر لم تصل. الخادم يطلب `city_id`، وقائمة متاجر فشل تحميلها كانت ستُقرأ «لا متاجر
  /// لك» فيضيف العميل متجره مرةً ثانية — فالشاشة تقول إنها لا تستطيع المتابعة بدل ذلك.
  const factory PlaceOrderState.failure(Failure failure) = PlaceOrderFailure;
}

extension PlaceOrderStateX on PlaceOrderState {
  /// المدينة المختارة، تُقرأ من القائمة ولا تُخزَّن مرتين.
  City? get selectedCity => switch (this) {
    PlaceOrderReady(:final cities, :final cityId) => () {
      for (final city in cities) {
        if (city.id == cityId) return city;
      }

      return null;
    }(),
    _ => null,
  };

  /// المناطق المعروضة، ولا شيء قبل اختيار مدينة.
  List<Region> get regions => selectedCity?.regions ?? const <Region>[];

  /// هل يُفتح «بيانات الطلب». سلةٌ فارغة لا خطوة بعدها.
  bool get canProceed => switch (this) {
    PlaceOrderReady(:final lines) => lines.isNotEmpty,
    _ => false,
  };

  /// هل يُضغط «أرسل الطلبية».
  ///
  /// **ثلاثة شروط، وكلٌّ منها قاعدةٌ للخادم لا قاعدةٌ مخترعة.** `items` مطلوبة وغير فارغة، و`city_id`
  /// مطلوب، ومدينةٌ تطلب منطقةً يقبلها `RequestOrderRequest` بلا منطقة — فهذه وحدها أشدّ من الخادم،
  /// لأن طلبيةً بلا حيّها طلبيةٌ على أحدٍ أن يتصل بالعميل من أجلها.
  bool get canSubmit => switch (this) {
    PlaceOrderReady(:final lines, :final cityId, :final regionId) =>
      lines.isNotEmpty &&
          cityId != null &&
          (!(selectedCity?.needsRegion ?? false) || regionId != null),
    _ => false,
  };

  bool get isSubmitting => switch (this) {
    PlaceOrderReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  /// التسعير حين وصل، أو `null` ما دام في الطريق أو فشل.
  BasketQuote? get quote => switch (this) {
    PlaceOrderReady(pricing: BasketPriced(:final quote)) => quote,
    _ => null,
  };

  /// سعر السطر رقم [index] ووحدته — **بمطابقة المنتج والمقاس لا بالموضع وحده**، فسطرٌ حُذف أثناء
  /// التسعير لا يُلبس سعرَ جاره.
  BasketLineQuote? quoteForLine(int index) {
    final quote = this.quote;
    if (quote == null) return null;

    final lines = switch (this) {
      PlaceOrderReady(:final lines) => lines,
      _ => const <OrderDraftLine>[],
    };
    if (index >= lines.length || index >= quote.lines.length) return null;

    final draft = lines[index].line;
    final priced = quote.lines[index];

    return priced.productId == draft.productId &&
            priced.productVariantId == draft.productVariantId
        ? priced
        : null;
  }

  /// رفض الخادم لرقم الاستلام، ليُعلَّق تحت حقله.
  String? get phoneError => switch (this) {
    PlaceOrderReady(lastFailure: ServerFailure(:final fieldErrors)) =>
      fieldErrors?['recipient_phone']?.firstOrNull,
    _ => null,
  };
}
