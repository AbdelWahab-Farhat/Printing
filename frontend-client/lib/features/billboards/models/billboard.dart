import 'package:freezed_annotation/freezed_annotation.dart';

part 'billboard.freezed.dart';
part 'billboard.g.dart';

/// Where tapping a banner leads.
///
/// **A decided answer, not two nullable columns.** The server sends `{"type": "product",
/// "product_id": 12}` rather than a pair of fields this app would have to read a rule into —
/// and a rule on the client is a rule kept in two places, which is a rule that will disagree
/// with itself. See `ClientBillboardResource::target()`.
///
/// `fallbackUnion` matters here: a target type added to the business after this build shipped
/// must not crash the home screen. It becomes [BillboardTarget.none] — a banner that leads
/// nowhere is exactly how an app that cannot act on a target should behave.
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake, fallbackUnion: 'none')
sealed class BillboardTarget with _$BillboardTarget {
  /// Opens a product in the catalogue.
  const factory BillboardTarget.product({
    @JsonKey(name: 'product_id') required int productId,
  }) = BillboardProductTarget;

  /// Leaves the app. **Never opened without asking** — a link in a banner is the one place
  /// where the shop can send a customer somewhere the shop does not control.
  const factory BillboardTarget.url({required String url}) = BillboardUrlTarget;

  /// A picture and nothing more. An announcement is allowed to just be an announcement.
  const factory BillboardTarget.none() = BillboardNoTarget;

  factory BillboardTarget.fromJson(Map<String, dynamic> json) =>
      _$BillboardTargetFromJson(json);
}

/// One banner on the home screen.
///
/// **The schedule never arrives.** `starts_at`, `ends_at`, `is_active` and `sort_order` are how
/// staff arrange the carousel; this app is sent only what is showing, already in order. A start
/// date it cannot act on tells it nothing — and tells anyone reading the traffic when a campaign
/// began.
@freezed
abstract class Billboard with _$Billboard {
  const factory Billboard({
    required int id,

    /// Doubles as the alt text a screen reader announces, which is why the server never sends
    /// it null.
    required String title,

    @JsonKey(name: 'image_url') required String imageUrl,

    /// The picture's own dimensions, so the carousel can reserve the right box before the
    /// image arrives — a home screen that jumps when each banner loads is a home screen that
    /// moves the thing somebody was about to tap.
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    @Default(BillboardTarget.none()) BillboardTarget target,
  }) = _Billboard;

  factory Billboard.fromJson(Map<String, dynamic> json) => _$BillboardFromJson(json);
}

extension BillboardX on Billboard {
  /// The box to reserve, when the server said. Falls back to a wide banner rather than a
  /// guess at zero, which would collapse the carousel.
  double get aspectRatio {
    final width = widthPx;
    final height = heightPx;

    if (width == null || height == null || width <= 0 || height <= 0) return 16 / 9;

    return width / height;
  }

  bool get leadsSomewhere => target is! BillboardNoTarget;
}
