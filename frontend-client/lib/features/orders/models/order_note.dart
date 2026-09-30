import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_note.freezed.dart';
part 'order_note.g.dart';

/// ما كتبه المتجر على الطلبية عند مراجعتها أو رفضها — والخادم وحده يقرّر أيّ الملاحظات تصل
/// العميل، فهذا التطبيق يرسم ما وصله كلّه.
///
/// **بلا اسمٍ لمن كتبها**: من يكتب للعميل هو المتجر، كرسائل الدعم.
@freezed
abstract class OrderNote with _$OrderNote {
  const factory OrderNote({
    required int id,

    /// المرحلة التي كُتبت عندها، بكلمة الخادم في [stageLabel]. ومرحلةٌ لا يعرفها هذا الإصدار
    /// تُقرأ [OrderStage.unknown] وتُرسم بكلمتها.
    @JsonKey(unknownEnumValue: OrderStage.unknown)
    @Default(OrderStage.unknown)
    OrderStage stage,
    @JsonKey(name: 'stage_label') required String stageLabel,
    required String text,
    @JsonKey(name: 'written_at') DateTime? writtenAt,
  }) = _OrderNote;

  factory OrderNote.fromJson(Map<String, dynamic> json) => _$OrderNoteFromJson(json);
}
