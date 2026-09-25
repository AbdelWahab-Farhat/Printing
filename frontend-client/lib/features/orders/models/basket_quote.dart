import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_quote.freezed.dart';
part 'basket_quote.g.dart';

/// السلة مسعّرةً من الخادم قبل إرسالها — «التكلفة النهائية» كما تعرضها تطبيقات التسوّق.
///
/// **التطبيق لا يضرب سعراً في كمية.** الخادم يسعّر السلة بالطريق الذي يسعّر به الطلبية حين تُرسل،
/// فالرقم هنا هو ما ستكلّفه — واختبارٌ في الخادم يثبت أنهما لا يفترقان.
///
/// **و`null` جوابٌ لا نقص.** سطرٌ «حسب الطلب» لا سعر له حتى يراجعه المتجر، ومدينةٌ لم يُتّفق على
/// سعر توصيلها لا رسم معروفاً لها — وفي الحالين لا مجموع، لأن مجموع المعروف وحده أصغر مما سيُطلب.
@freezed
abstract class BasketQuote with _$BasketQuote {
  const factory BasketQuote({
    /// بترتيب السلة نفسه.
    @Default(<BasketLineQuote>[]) List<BasketLineQuote> lines,

    /// مجموع البضاعة.
    @JsonKey(name: 'items_total') String? itemsTotal,

    /// رسم المندوب إلى المدينة المختارة، يُدفع له عند الاستلام. `"0.00"` للاستلام من المكتب.
    @JsonKey(name: 'delivery_price') String? deliveryPrice,

    /// البضاعة مع التوصيل: ما يدفعه العميل في النهاية.
    @JsonKey(name: 'total_with_delivery') String? totalWithDelivery,
  }) = _BasketQuote;

  factory BasketQuote.fromJson(Map<String, dynamic> json) => _$BasketQuoteFromJson(json);
}

/// سطرٌ من السلة مسعّراً.
@freezed
abstract class BasketLineQuote with _$BasketLineQuote {
  const factory BasketLineQuote({
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_variant_id') required int productVariantId,

    /// «قطعة» أو «كجم» — بأيّهما تُحسب الكمية.
    @JsonKey(name: 'unit_label') String? unitLabel,
    @JsonKey(name: 'unit_price') String? unitPrice,

    /// `null` لمنتجٍ «حسب الطلب»: يُسعّره المتجر حين يقبل الطلبية.
    @JsonKey(name: 'line_total') String? lineTotal,
  }) = _BasketLineQuote;

  factory BasketLineQuote.fromJson(Map<String, dynamic> json) => _$BasketLineQuoteFromJson(json);
}
