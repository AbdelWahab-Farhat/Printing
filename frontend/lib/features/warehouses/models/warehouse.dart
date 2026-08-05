import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse.freezed.dart';
part 'warehouse.g.dart';

/// What a warehouse is *for*, as the server's own enum.
///
/// `unknown` rather than a throw: the shop can add a fourth kind before this build reaches a
/// phone, and a warehouse we cannot classify is still a warehouse whose stock must be readable.
/// Nothing branches on a particular case — [Warehouse.typeLabel] is the server's Arabic — so a
/// new one renders correctly with a neutral glyph.
enum WarehouseType {
  @JsonValue('main')
  main,
  @JsonValue('operational')
  operational,
  @JsonValue('showroom')
  showroom,
  unknown,
}

/// مخزن — a place stock sits.
@freezed
abstract class Warehouse with _$Warehouse {
  const factory Warehouse({
    required int id,
    required String name,

    @JsonKey(unknownEnumValue: WarehouseType.unknown) required WarehouseType type,

    /// The server's Arabic for [type], so the app keeps no translation table.
    @JsonKey(name: 'type_label') required String typeLabel,

    String? location,

    /// How many balance lines sit in it — «٤٢ صنفاً», not how many pieces.
    @JsonKey(name: 'stocks_count') int? stocksCount,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Warehouse;

  const Warehouse._();

  factory Warehouse.fromJson(Map<String, dynamic> json) => _$WarehouseFromJson(json);

  /// Whether anything is recorded in it. The server refuses to delete a warehouse that still
  /// holds stock, and this is what lets the screen say so before the button is pressed.
  bool get holdsStock => (stocksCount ?? 1) > 0;
}
