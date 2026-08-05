import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/business_fields/models/business_field.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// Someone the printing business sells to.
///
/// One class, not an entity plus a model — `@JsonKey` is the seam that keeps a rename on the
/// backend from reaching the widgets, and it is the only seam that was ever doing that work.
@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    required int id,

    /// The permanent human-facing identifier — `C1`, `C2`, `C3` … Allocated by the server and
    /// never sent by this app: it is read-only here by construction, not by convention.
    required String code,

    required String name,
    required String phone,

    /// A customer is deactivated, never deleted, so their orders keep pointing at a row that
    /// still exists. There is no destroy endpoint to call.
    @JsonKey(name: 'is_active') required bool isActive,

    /// Absent — not empty — when the API did not load them. `whenLoaded` on the backend means
    /// a missing key rather than `[]`, and "we did not ask" is a different fact from "this
    /// customer has none".
    List<CustomerShop>? shops,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Customer;

  const Customer._();

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

  /// True only when shops were loaded *and* there is at least one — a screen that shows
  /// "لا توجد محلات" must not say it about a customer whose shops were simply not requested.
  bool get hasShops => (shops ?? const []).isNotEmpty;
}

/// A place a customer sells from, pinned on the map.
@freezed
abstract class CustomerShop with _$CustomerShop {
  const factory CustomerShop({
    required int id,
    required String name,

    /// Numbers, not strings: these go straight into a map SDK. Null only for shops recorded
    /// before coordinates existed — a new one cannot be created without them.
    double? latitude,
    double? longitude,

    @JsonKey(name: 'page_url') String? pageUrl,

    /// مجال العمل — what this shop sells. Null for the shops recorded before the list existed,
    /// and for one entered in a hurry; «لم يُحدَّد» is a real answer here, not a missing one.
    @JsonKey(name: 'business_field_id') int? businessFieldId,

    /// The trade itself, so a screen renders its name without fetching the list to translate
    /// one number. Sent whenever the shop is loaded with it.
    @JsonKey(name: 'business_field') BusinessField? businessField,
  }) = _CustomerShop;

  const CustomerShop._();

  factory CustomerShop.fromJson(Map<String, dynamic> json) => _$CustomerShopFromJson(json);

  bool get hasPin => latitude != null && longitude != null;
}
