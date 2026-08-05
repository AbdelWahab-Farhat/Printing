import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_field.freezed.dart';
part 'business_field.g.dart';

/// مجال العمل — the trade a customer's shop is in: شحن وتوصيل, بيع ملابس, مطاعم ومقاهي …
///
/// Reference data the business curates from its own screen. Nothing in the app branches on a
/// particular field, and nothing should: the list is the shop's to shape, and code that knows
/// «شحن» by name would break the first time somebody renames it.
@freezed
abstract class BusinessField with _$BusinessField {
  const factory BusinessField({
    required int id,
    required String name,

    /// Whether it is still offered when recording a shop. A stopped field stays on the shops
    /// already recorded under it — it leaves the picker, it does not retract anything.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// Where it sits in the picker. The business's own order, not alphabetical.
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,

    /// How many shops are recorded in this trade. Present on the list and on a single field.
    ///
    /// It is also what says whether deleting will be refused — the server allows a delete only
    /// while this is zero — so the screen can explain that before the button is pressed.
    @JsonKey(name: 'shops_count') int? shopsCount,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _BusinessField;

  const BusinessField._();

  factory BusinessField.fromJson(Map<String, dynamic> json) => _$BusinessFieldFromJson(json);

  /// Whether any shop points at this field. `null` — the count was not asked for — reads as
  /// "assume it is in use", because refusing a delete wrongly is recoverable and the opposite
  /// is a confusing 422 the user cannot act on.
  bool get isInUse => (shopsCount ?? 1) > 0;
}
