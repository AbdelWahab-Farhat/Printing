import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_purchase_order_option.freezed.dart';
part 'fund_purchase_order_option.g.dart';

/// أمرُ شراءٍ أدخل للصندوق بضاعةً — خيارٌ في حقل «أمر الشراء» بورقة المصروف.
///
/// Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md: مصروفٌ يُربط به يتوزّع على كل وحدةٍ أدخلها —
/// ما بقي على الرفّ تحمله تكلفتُه، وما بِيع يُكتب على فترة بيعه. **الخادمُ لا يعرض إلا ما يقبله**،
/// فلا خيارَ هنا يُرفض عند الحفظ.
@freezed
abstract class FundPurchaseOrderOption with _$FundPurchaseOrderOption {
  const factory FundPurchaseOrderOption({
    required int id,
    String? vendor,
    @JsonKey(name: 'order_date') String? orderDate,
    @JsonKey(name: 'received_on') String? receivedOn,

    /// أسماءُ ما اشتراه الصندوقُ منه — ليُعرف دون أن يُفتح.
    @Default(<String>[]) List<String> items,
  }) = _FundPurchaseOrderOption;

  factory FundPurchaseOrderOption.fromJson(Map<String, dynamic> json) =>
      _$FundPurchaseOrderOptionFromJson(json);
}
