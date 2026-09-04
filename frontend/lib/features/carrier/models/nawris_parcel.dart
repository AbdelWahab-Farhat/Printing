import 'package:freezed_annotation/freezed_annotation.dart';

part 'nawris_parcel.freezed.dart';
part 'nawris_parcel.g.dart';

/// A parcel as Nawris knows it — the receipt for handing an order to the carrier.
///
/// **Their code is the useful field, and it is theirs.** [code] is what a colleague reads down
/// the phone to Nawris and what their own portal searches by; nothing in this app generates it or
/// can reconstruct it. That is why the answer to «إرسال للنورس» is parsed at all rather than
/// discarded as a bare 201 — without showing it, the clerk who pressed the button has no way of
/// proving the parcel exists.
///
/// **[amountToCollect] is not the order's total**, and reading it as one is the mistake this
/// model exists to prevent: it is what remains on the order *less* our delivery fee, because the
/// courier adds their own at the door. See NAWRIS-INTEGRATION.md §5.2.
///
/// Money travels as `String` here exactly as it does everywhere else in this app — never parsed
/// to a double on the way in.
///
/// Mirrors `NawrisParcelResource.php`.
@freezed
abstract class NawrisParcel with _$NawrisParcel {
  const factory NawrisParcel({
    required int id,

    /// Their identifier for this parcel. Shown to the person who dispatched it.
    required String code,

    /// Ours — minted at dispatch so a duplicate hand-over is detectable on both sides.
    String? reference,

    @JsonKey(name: 'bar_code') String? barCode,

    /// Their government and area ids, resolved from the order's own city and region. Kept
    /// because a parcel that went to the wrong place is diagnosed by comparing these two
    /// against the city that was picked.
    String? government,
    String? area,

    /// The COD we asked them to collect.
    @JsonKey(name: 'amount_to_collect') String? amountToCollect,

    /// Our delivery fee, taken off the COD before dispatch and frozen here. The customer pays it
    /// to the courier, so it never reaches our drawer.
    @JsonKey(name: 'delivery_price_deducted') String? deliveryPriceDeducted,

    /// What they actually collected — null until a delivery is reported.
    @JsonKey(name: 'collected_amount') String? collectedAmount,

    /// Their integer and their prose. The status mapping is written against the first; the
    /// second is what support reads, and it is never interpreted.
    @JsonKey(name: 'remote_status_code') int? remoteStatusCode,
    @JsonKey(name: 'remote_status_text') String? remoteStatusText,

    @JsonKey(name: 'is_open') @Default(false) bool isOpen,
    @JsonKey(name: 'has_open_conflict') @Default(false) bool hasOpenConflict,

    @JsonKey(name: 'dispatched_at') DateTime? dispatchedAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
  }) = _NawrisParcel;

  factory NawrisParcel.fromJson(Map<String, dynamic> json) =>
      _$NawrisParcelFromJson(json);
}
