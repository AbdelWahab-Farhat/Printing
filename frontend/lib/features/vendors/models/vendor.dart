import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor.freezed.dart';
part 'vendor.g.dart';

/// المورد — a supplier the business buys stock from.
///
/// **Deactivated, never deleted**, which is why there is no delete anywhere in this feature: a
/// vendor who stopped supplying us last year still carried a hundred shipments, and every one of
/// those documents has to keep naming them. `isActive` is what retires one — the same rule
/// `Customer` and `ShippingCompany` already follow.
@freezed
abstract class Vendor with _$Vendor {
  const factory Vendor({
    required int id,
    required String name,

    /// Who to actually ask for. A company answers its phone; this is the person on the other
    /// end of it, and the field is optional because plenty of suppliers are one man.
    @JsonKey(name: 'contact_person') String? contactPerson,

    /// Required, and unique across vendors — a `422` on this field means another vendor already
    /// holds the number, which is the server catching the same supplier being entered twice.
    required String phone,

    String? email,
    String? address,

    @JsonKey(name: 'is_active') required bool isActive,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Vendor;

  const Vendor._();

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);

  /// «محمد علي · 0912345678», or just the number for a vendor with nobody named.
  String get contactLine =>
      contactPerson == null || contactPerson!.isEmpty ? phone : '$contactPerson · $phone';
}
