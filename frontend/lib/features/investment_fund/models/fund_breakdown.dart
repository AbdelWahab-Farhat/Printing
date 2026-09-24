import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_breakdown.freezed.dart';
part 'fund_breakdown.g.dart';

/// حركةٌ في خزينة الصندوق — ما جاء منه المال أو ذهب إليه، وما بقي بعده.
///
/// **الصفوفُ القائمة وحدها.** تحصيلُ الطلبية يُصحَّح بعكسٍ ثم صفٍّ جديد كلّما دفع العميل دفعة،
/// والخادمُ يعرض ما بقي قائماً لا خطواتِ الحساب — فمجموعُ السجلّ هو نقدُ اللوحة بعينه.
@freezed
abstract class FundCashEntry with _$FundCashEntry {
  const factory FundCashEntry({
    required int id,
    required String type,
    @JsonKey(name: 'type_label') required String typeLabel,

    /// أدخل هذا الصفُّ مالاً أم أخرجه — من نوعه في الخادم، لا من إشارةٍ تُخمَّن هنا.
    @JsonKey(name: 'is_inflow') required bool isInflow,

    /// المبلغُ بإشارته: «-3000.00» لما خرج.
    @JsonKey(name: 'signed_amount') required String signedAmount,

    /// ما بقي في الخزينة بعد هذا الصفّ — يُحسب في الخادم على الدفتر كلِّه، فالصفحةُ الثانية لا
    /// تبدأ من صفر.
    @JsonKey(name: 'balance_after') required String balanceAfter,

    @JsonKey(name: 'occurred_at') DateTime? occurredAt,

    /// «طلبية ORD-12 · محمد»، «أمر شراء #3 · مصنع الأكياس»، «عبدالرحمن» — يبنيه الخادم.
    String? description,

    /// إلى أين تُفتح الحركة، إن كان لها بابٌ في التطبيق.
    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'purchase_order_id') int? purchaseOrderId,
    @JsonKey(name: 'investor_id') int? investorId,

    String? notes,
  }) = _FundCashEntry;

  factory FundCashEntry.fromJson(Map<String, dynamic> json) => _$FundCashEntryFromJson(json);
}

/// مادّةٌ على رفّ الصندوق: كم منها، وبكم كلّفت.
@freezed
abstract class FundShelfMaterial with _$FundShelfMaterial {
  const factory FundShelfMaterial({
    @JsonKey(name: 'stock_item_id') int? stockItemId,
    String? code,
    String? name,
    @JsonKey(name: 'unit_label') String? unitLabel,
    required String quantity,

    /// بالتكلفة المجمّدة يوم وصلت — ما يدخل به الرفُّ قيمةَ الصندوق.
    required String value,

    @Default(0) int batches,
  }) = _FundShelfMaterial;

  factory FundShelfMaterial.fromJson(Map<String, dynamic> json) =>
      _$FundShelfMaterialFromJson(json);
}

/// بضاعةُ الصندوق على الرفّ — رقمُ اللوحة وموادُّه.
@freezed
abstract class FundShelf with _$FundShelf {
  const factory FundShelf({
    /// رقمُ اللوحة بعينه، لا جمعُ الصفوف: كلُّ صفٍّ مقرَّبٌ لنفسه.
    required String total,
    @Default(<FundShelfMaterial>[]) List<FundShelfMaterial> materials,
  }) = _FundShelf;

  factory FundShelf.fromJson(Map<String, dynamic> json) => _$FundShelfFromJson(json);
}

/// بندا البضاعة الخارجة في اللوحة — كلٌّ منهما يُفتح على طلبياته.
enum FundGoodsStage {
  /// خرجت من الرفّ ولم تصل العميل.
  inFlight,

  /// وصلت العميل ولم يُحصَّل ثمنُها كاملاً.
  uncollected,
}

/// ما أخذته طلبيةٌ من مادّةٍ واحدة من رفوف الصندوق.
@freezed
abstract class FundGoodsLine with _$FundGoodsLine {
  const factory FundGoodsLine({
    @JsonKey(name: 'stock_item_id') int? stockItemId,
    String? code,
    String? name,
    @JsonKey(name: 'unit_label') String? unitLabel,
    required String quantity,
    required String cost,
  }) = _FundGoodsLine;

  factory FundGoodsLine.fromJson(Map<String, dynamic> json) => _$FundGoodsLineFromJson(json);
}

/// طلبيةٌ تحمل بضاعةَ الصندوق خارج الرفّ — في الطريق، أو عند عميلٍ لم يدفع.
@freezed
abstract class FundGoodsOrder with _$FundGoodsOrder {
  const factory FundGoodsOrder({
    @JsonKey(name: 'order_id') required int orderId,
    required String code,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'placed_at') DateTime? placedAt,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @JsonKey(name: 'grand_total') required String grandTotal,
    @JsonKey(name: 'paid_amount') required String paidAmount,

    /// ما بقي على العميل، لا أقلَّ من صفر.
    required String remaining,

    /// تكلفةُ بضاعة الصندوق فيها — ما تدخل به قيمتَه.
    required String cost,

    @Default(<FundGoodsLine>[]) List<FundGoodsLine> goods,
  }) = _FundGoodsOrder;

  factory FundGoodsOrder.fromJson(Map<String, dynamic> json) => _$FundGoodsOrderFromJson(json);
}

/// بندٌ من بندَي البضاعة الخارجة: رقمُه في اللوحة، وطلبياتُه.
@freezed
abstract class FundGoodsOut with _$FundGoodsOut {
  const factory FundGoodsOut({
    required String total,
    @Default(<FundGoodsOrder>[]) List<FundGoodsOrder> orders,
  }) = _FundGoodsOut;

  factory FundGoodsOut.fromJson(Map<String, dynamic> json) => _$FundGoodsOutFromJson(json);
}

/// مادّةٌ في أمر شراءٍ دفع الصندوقُ ثمنَه — كم طُلب منها، وكم وصل، وكم بقي، وبكم.
@freezed
abstract class FundOnOrderLine with _$FundOnOrderLine {
  const factory FundOnOrderLine({
    @JsonKey(name: 'stock_item_id') int? stockItemId,
    String? code,
    String? name,
    @JsonKey(name: 'unit_label') String? unitLabel,
    @JsonKey(name: 'quantity_ordered') required String quantityOrdered,
    @JsonKey(name: 'quantity_received') required String quantityReceived,
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,

    /// التكلفةُ الواصلة لما لم يصل — ما يدخل به قيمةَ الصندوق.
    required String value,
  }) = _FundOnOrderLine;

  factory FundOnOrderLine.fromJson(Map<String, dynamic> json) => _$FundOnOrderLineFromJson(json);
}

/// أمرُ شراءٍ خرج ثمنُه من الخزينة ولم تصل بضاعتُه — كلُّها أو بعضُها.
@freezed
abstract class FundPurchaseOnOrder with _$FundPurchaseOnOrder {
  const factory FundPurchaseOnOrder({
    @JsonKey(name: 'purchase_order_id') required int purchaseOrderId,
    @JsonKey(name: 'vendor_name') String? vendorName,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'order_date') DateTime? orderDate,
    @JsonKey(name: 'expected_date') DateTime? expectedDate,
    required String value,
    @Default(<FundOnOrderLine>[]) List<FundOnOrderLine> lines,
  }) = _FundPurchaseOnOrder;

  factory FundPurchaseOnOrder.fromJson(Map<String, dynamic> json) =>
      _$FundPurchaseOnOrderFromJson(json);
}

/// «بضاعة مشتراة لم تصل» — رقمُ اللوحة وأوامرُه.
@freezed
abstract class FundOnOrder with _$FundOnOrder {
  const factory FundOnOrder({
    required String total,
    @Default(<FundPurchaseOnOrder>[]) List<FundPurchaseOnOrder> orders,
  }) = _FundOnOrder;

  factory FundOnOrder.fromJson(Map<String, dynamic> json) => _$FundOnOrderFromJson(json);
}

/// سطرٌ في الربح المستحقّ ليس طلبية — مصروفٌ، أو خسارةٌ رُحِّلت، أو تسوية.
///
/// **بإشارته**: مصروفٌ أكل من الربح يُقرأ «-20» لا «20».
@freezed
abstract class FundProfitAdjustment with _$FundProfitAdjustment {
  const factory FundProfitAdjustment({
    required String kind,
    required String label,
    required String amount,
  }) = _FundProfitAdjustment;

  factory FundProfitAdjustment.fromJson(Map<String, dynamic> json) =>
      _$FundProfitAdjustmentFromJson(json);
}

/// ربحٌ لم يُفرَج عنه بعد — طلبيةً طلبية، وتحت كلٍّ منها نصيبُ كلِّ شريك.
@freezed
abstract class FundUnreleasedProfit with _$FundUnreleasedProfit {
  const factory FundUnreleasedProfit({
    @Default('0.00') String total,

    /// بطاقةُ شاشة الفترة نفسُها: رمزُ الطلبية، وحالتُها، ونصيبُ كلِّ شريكٍ منها.
    @Default(<PeriodOrder>[]) List<PeriodOrder> orders,

    @Default(<FundProfitAdjustment>[]) List<FundProfitAdjustment> adjustments,
  }) = _FundUnreleasedProfit;

  factory FundUnreleasedProfit.fromJson(Map<String, dynamic> json) =>
      _$FundUnreleasedProfitFromJson(json);
}

/// ربحٌ أُفرج عنه ولم يُسحب — لكلِّ صاحبٍ رصيدُه.
///
/// **لا طلبيةَ هنا**: الإفراجُ صفٌّ لفترةٍ كاملة والسحبُ من المحفظة كلِّها، فنسبةُ الباقي إلى
/// طلبيةٍ بعينها قسمةٌ تُخترع لا واقعةٌ في الدفتر.
@freezed
abstract class FundWalletProfit with _$FundWalletProfit {
  const factory FundWalletProfit({
    @Default('0.00') String total,
    @Default(<PeriodInvestorShare>[]) List<PeriodInvestorShare> investors,
  }) = _FundWalletProfit;

  factory FundWalletProfit.fromJson(Map<String, dynamic> json) =>
      _$FundWalletProfitFromJson(json);
}

/// الأرباحُ المستحقّة للمستثمرين — رقمُ اللوحة بنصفيه.
@freezed
abstract class FundProfitOwed with _$FundProfitOwed {
  const factory FundProfitOwed({
    required String total,
    @Default(FundUnreleasedProfit()) FundUnreleasedProfit unreleased,
    @JsonKey(name: 'in_wallets') @Default(FundWalletProfit()) FundWalletProfit inWallets,
  }) = _FundProfitOwed;

  factory FundProfitOwed.fromJson(Map<String, dynamic> json) => _$FundProfitOwedFromJson(json);
}
