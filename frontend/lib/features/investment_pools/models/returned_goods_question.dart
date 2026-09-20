import 'package:freezed_annotation/freezed_annotation.dart';

part 'returned_goods_question.freezed.dart';
part 'returned_goods_question.g.dart';

/// «بضاعة راجعة من طلبية ملغاة: صالحة أم تالفة؟»
///
/// **The one fact the system cannot work out for itself.** When a printed order is cancelled its
/// material is credited back to the shelf **as good stock**, and paper that has been through a
/// press is not good stock — the movement ledger records quantities, not whether there is ink on
/// them.
///
/// So it is asked of a person, and **the period will not close until it is answered**. That
/// friction is deliberate: the alternative is a distribution computed on goods that do not exist,
/// paid into wallets it can be withdrawn from that afternoon.
///
/// [quantity] and [cost] were read off the credit-back the day the question was raised, not today.
/// The shelf has moved on since; the answer has to be about what actually came back.
@freezed
abstract class ReturnedGoodsQuestion with _$ReturnedGoodsQuestion {
  const factory ReturnedGoodsQuestion({
    required int id,
    @JsonKey(name: 'investment_pool_id') required int investmentPoolId,

    @JsonKey(name: 'order_id') required int orderId,
    @JsonKey(name: 'order_item_id') required int orderItemId,
    @JsonKey(name: 'order_code') String? orderCode,

    @JsonKey(name: 'stock_item_id') required int stockItemId,
    @JsonKey(name: 'stock_item_name') String? stockItemName,

    required String quantity,

    /// **What the answer is worth**, and the screen should show it: «تالفة» charges exactly this
    /// to the pool and takes the goods off the shelf. The person answering is deciding a figure,
    /// not ticking a box.
    required String cost,

    /// `open`, `good` or `damaged`.
    required String verdict,
    @JsonKey(name: 'verdict_label') required String verdictLabel,
    @JsonKey(name: 'is_open') @Default(true) bool isOpen,

    @JsonKey(name: 'answered_at') String? answeredAt,
    @JsonKey(name: 'answered_by') int? answeredBy,
    @JsonKey(name: 'answered_by_name') String? answeredByName,

    /// The difference between «we checked» and «something happened». «صالحة» leaves it null,
    /// because the goods really are back and really are usable.
    @JsonKey(name: 'damage_movement_id') int? damageMovementId,

    String? notes,
  }) = _ReturnedGoodsQuestion;

  factory ReturnedGoodsQuestion.fromJson(Map<String, dynamic> json) =>
      _$ReturnedGoodsQuestionFromJson(json);
}
