import 'package:freezed_annotation/freezed_annotation.dart';

part 'shipping_company.freezed.dart';
part 'shipping_company.g.dart';

/// A company that carries our parcels.
///
/// A record rather than a name typed onto each order: one company, one spelling, one phone
/// number to ring when a parcel goes missing, and a way to stop offering it without erasing the
/// orders it already carried.
///
/// Mirrors `ShippingCompany.php`.
@freezed
abstract class ShippingCompany with _$ShippingCompany {
  const factory ShippingCompany({
    required int id,
    required String name,

    /// The office you ring. Null because a company can be added the moment it is needed, from
    /// a screen where nobody has the number to hand.
    String? phone,
    String? notes,

    /// Whether it is offered on a new dispatch. Old orders naming it are unaffected.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// Whether a dispatch form opens on this company.
    ///
    /// At most one does — «من سيأخذها» has the same answer nine times in ten, and this is the
    /// business saying which. Absent means no: a server too old to know the flag is a business
    /// that has not named one.
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ShippingCompany;

  const ShippingCompany._();

  factory ShippingCompany.fromJson(Map<String, dynamic> json) =>
      _$ShippingCompanyFromJson(json);

  /// What the card shows under the name.
  String get subtitle => phone ?? 'بلا رقم هاتف';
}
