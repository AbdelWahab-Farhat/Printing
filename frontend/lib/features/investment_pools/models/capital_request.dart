import 'package:freezed_annotation/freezed_annotation.dart';

part 'capital_request.freezed.dart';
part 'capital_request.g.dart';

/// Capital offered to a pool, or asked back from it.
///
/// **Why a request and not a movement.** Ownership of a pool is a plain capital ratio, and that is
/// only exact if capital does not move inside a period. So money offered late joins the next
/// period, and money asked back leaves at the close — after that period's profit has been divided,
/// so a man who says in September that he wants out is still paid his September share.
///
/// A pending request has **moved nothing**: the investor's money has been in his own wallet the
/// whole time, which is why cancelling one unwinds nothing.
@freezed
abstract class CapitalRequest with _$CapitalRequest {
  const factory CapitalRequest({
    required int id,
    @JsonKey(name: 'investment_pool_id') required int investmentPoolId,
    @JsonKey(name: 'investor_id') required int investorId,
    CapitalRequestInvestor? investor,

    /// `in` or `out`.
    required String direction,
    @JsonKey(name: 'direction_label') required String directionLabel,

    required String amount,

    /// `pending`, `applied` or `cancelled`.
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'can_be_cancelled') @Default(false) bool canBeCancelled,

    @JsonKey(name: 'requested_at') String? requestedAt,

    /// Null while pending — the period it will join does not exist yet, and naming a row that has
    /// not been created would be a promise this cannot keep.
    @JsonKey(name: 'effective_period_id') int? effectivePeriodId,

    /// **What a screen should key «تمّت» off**, not the status alone: it is the wallet row this
    /// became, and its presence is the only proof the money actually moved.
    @JsonKey(name: 'applied_entry_id') int? appliedEntryId,

    String? notes,
  }) = _CapitalRequest;

  factory CapitalRequest.fromJson(Map<String, dynamic> json) =>
      _$CapitalRequestFromJson(json);
}

@freezed
abstract class CapitalRequestInvestor with _$CapitalRequestInvestor {
  const factory CapitalRequestInvestor({
    required int id,
    String? name,
  }) = _CapitalRequestInvestor;

  factory CapitalRequestInvestor.fromJson(Map<String, dynamic> json) =>
      _$CapitalRequestInvestorFromJson(json);
}

/// What opening a period did with the queue behind it.
///
/// [short] is keyed by request id and is **empty on the ordinary open**, which is most of them. A
/// man whose wallet could no longer cover what he had asked for keeps his request pending and the
/// period opens regardless — one person's spending must not stop a pool's month from starting.
@freezed
abstract class PeriodOpened with _$PeriodOpened {
  const factory PeriodOpened({
    @Default(<CapitalRequest>[]) List<CapitalRequest> applied,
    @Default(<String, dynamic>{}) Map<String, dynamic> short,
  }) = _PeriodOpened;

  factory PeriodOpened.fromJson(Map<String, dynamic> json) =>
      _$PeriodOpenedFromJson(json);
}
