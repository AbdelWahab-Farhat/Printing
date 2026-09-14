import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortage.freezed.dart';
part 'shortage.g.dart';

/// Where a shortage is in the chase for the goods.
///
/// **Unlike `PurchaseOrderStatus`, this enum holds no transition map**, and that is deliberate:
/// every shortage payload carries `available_transitions`, already the server's own answer for
/// this row and this reader. A copy in Dart would be a second rule to keep in step, and the
/// first thing it would get wrong is «مكتمل» — which is in no map at all, because it is written
/// by arithmetic when the remainder reaches zero and is never anybody's to choose.
enum ShortageStatus {
  @JsonValue('new')
  fresh('new', 'جديد'),
  @JsonValue('searching')
  searching('searching', 'جاري البحث'),
  @JsonValue('unavailable')
  unavailable('unavailable', 'غير متوفر'),
  @JsonValue('completed')
  completed('completed', 'مكتمل'),

  /// A status this build has never heard of. Reached through `unknownEnumValue`, so one new case
  /// on the server does not turn a whole page into a parse failure.
  ///
  /// **Read, never offered.** The filter sheet lists [offered], which leaves it out: a chip
  /// nobody can name is a chip nobody can use.
  unknown('', '');

  const ShortageStatus(this.wire, this.label);

  final String wire;

  /// Mirrors the server's own `label()`. Held here because the filter sheet has to name all four
  /// before a single shortage has been loaded.
  final String label;

  /// The four a person may filter by — everything this build can name.
  static List<ShortageStatus> get offered =>
      values.where((status) => status != ShortageStatus.unknown).toList(growable: false);
}

/// Where the shortage came from, which decides whether it may be edited here at all.
enum ShortageSource {
  /// Somebody wrote it down: «شريط لاصق عريض». Editable in this section.
  @JsonValue('manual')
  manual('manual'),

  /// Mirrored from a line of an order that came up short. **Its quantity belongs to the order
  /// screen** — see `Shortage.isEditable`, which the server answers rather than this enum.
  @JsonValue('order')
  order('order'),

  unknown('');

  const ShortageSource(this.wire);

  final String wire;
}

/// One move this shortage may make, as the server offers it.
///
/// **The whole of what draws the status buttons.** A screen that drew every status it knows would
/// offer «مكتمل», which the API answers «لا يُحوَّل النقص إلى «مكتمل» يدوياً».
@freezed
abstract class ShortageTransition with _$ShortageTransition {
  const factory ShortageTransition({required String value, required String label}) =
      _ShortageTransition;

  factory ShortageTransition.fromJson(Map<String, dynamic> json) =>
      _$ShortageTransitionFromJson(json);
}

/// The order a shortage was mirrored from, as much of it as a card needs.
///
/// `isArchived` is why it is here rather than left to the id: a shortage whose order has been
/// archived is refused to anybody without `orders.archive.view`, and the screen that says so
/// reads it off this.
@freezed
abstract class ShortageOrderRef with _$ShortageOrderRef {
  const factory ShortageOrderRef({
    required int id,
    required String code,
    String? status,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
  }) = _ShortageOrderRef;

  factory ShortageOrderRef.fromJson(Map<String, dynamic> json) => _$ShortageOrderRefFromJson(json);
}

/// A person on a shortage — who it is assigned to, and who wrote it down.
///
/// `employeeCode` is absent on a creator and present on an assignee; both parse through this.
@freezed
abstract class ShortagePerson with _$ShortagePerson {
  const factory ShortagePerson({
    required int id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
  }) = _ShortagePerson;

  factory ShortagePerson.fromJson(Map<String, dynamic> json) => _$ShortagePersonFromJson(json);
}

/// The customer waiting on the goods, named for the card.
@freezed
abstract class ShortageCustomerRef with _$ShortageCustomerRef {
  const factory ShortageCustomerRef({required int id, required String name, String? phone}) =
      _ShortageCustomerRef;

  factory ShortageCustomerRef.fromJson(Map<String, dynamic> json) =>
      _$ShortageCustomerRefFromJson(json);
}

/// The catalogue row behind a stockable shortage, and the size under it.
@freezed
abstract class ShortageProductRef with _$ShortageProductRef {
  const factory ShortageProductRef({required int id, required String name}) = _ShortageProductRef;

  factory ShortageProductRef.fromJson(Map<String, dynamic> json) =>
      _$ShortageProductRefFromJson(json);
}

/// One size of it.
@freezed
abstract class ShortageVariantRef with _$ShortageVariantRef {
  const factory ShortageVariantRef({required int id, required String label}) = _ShortageVariantRef;

  factory ShortageVariantRef.fromJson(Map<String, dynamic> json) =>
      _$ShortageVariantRefFromJson(json);
}

/// Something the shop is short of, and the chase to get it.
///
/// **Two doors, and this app sees both.** An employee closes a shortage from the نواقص section by
/// recording what they bought; a colleague closes the same one from the order screen, by typing
/// what arrived when the order leaves «نواقص». Both are real, so a shortage can change without
/// this screen having touched it — and the sync runs on a queued listener, so it is not instant.
/// Pull to refresh; do not re-fetch after an order write and expect the new number.
///
/// **Every quantity and every amount is a `String`.** Three decimals on quantities, two on money,
/// exactly as `Order` and `PurchaseOrder` carry theirs. Parse only to compare, never to display:
/// a `double` is where a figure stops being the one the server printed.
///
/// **[remainingQuantity] is sent and never computed.** A subtraction in Dart would be a second
/// implementation of the rule that decides when a shortage is finished, and the two would
/// disagree the first time rounding entered it.
///
/// **The nested objects are `whenLoaded` on the server**, so on the *list* they are absent from
/// the JSON — not null, absent. Every one of them is nullable here and the matching `*_id` is
/// always there to fall back on. [supplies] arrives on the detail endpoint alone: a page of forty
/// shortages has no use for four hundred ledger rows.
@freezed
abstract class Shortage with _$Shortage {
  const factory Shortage({
    required int id,
    required String code,

    @JsonKey(unknownEnumValue: ShortageSource.unknown) required ShortageSource source,
    @JsonKey(name: 'source_label') required String sourceLabel,

    /// «كيس شحن — 25*35», or whatever somebody typed on a manual one.
    required String name,

    /// The unit the quantities are counted in, and the server's own word for it. The label is
    /// what every screen prints; nothing branches on the value.
    String? unit,
    @JsonKey(name: 'unit_label') String? unitLabel,

    @JsonKey(name: 'required_quantity') required String requiredQuantity,
    @JsonKey(name: 'supplied_quantity') required String suppliedQuantity,
    @JsonKey(name: 'remaining_quantity') required String remainingQuantity,
    @JsonKey(name: 'total_paid') required String totalPaid,

    @JsonKey(unknownEnumValue: ShortageStatus.unknown) required ShortageStatus status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'is_final') @Default(false) bool isFinal,

    /// Exactly the buttons to draw, and no others — see [ShortageTransition].
    @JsonKey(name: 'available_transitions')
    @Default(<ShortageTransition>[])
    List<ShortageTransition> availableTransitions,

    /// Whether the form may be opened on it. **False on a shortage born of an order**, whose
    /// quantity is corrected from the order screen — the server says so rather than the app
    /// deriving it from [source], because the rule is the server's.
    @JsonKey(name: 'is_editable') @Default(false) bool isEditable,

    /// Whether the goods have a shelf to land on.
    ///
    /// **Read, never inferred.** Deriving it from `product_variant_id` would put a warehouse
    /// picker in front of a roll of tape — and sending a warehouse for one is a 422 in its own
    /// right, because the caller would be telling the server goods are moving when they are not.
    @JsonKey(name: 'is_stockable') @Default(false) bool isStockable,

    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'order_item_id') int? orderItemId,
    ShortageOrderRef? order,

    @JsonKey(name: 'customer_id') int? customerId,
    ShortageCustomerRef? customer,

    @JsonKey(name: 'product_id') int? productId,
    @JsonKey(name: 'product_variant_id') int? productVariantId,
    ShortageProductRef? product,
    ShortageVariantRef? variant,

    @JsonKey(name: 'assigned_to_user_id') int? assignedToUserId,
    ShortagePerson? assignee,
    @JsonKey(name: 'created_by_user_id') int? createdByUserId,
    ShortagePerson? creator,

    String? description,

    /// The ledger — **detail payload only**, so an empty list on a card means «not asked for»
    /// rather than «nothing happened».
    @Default(<ShortageSupply>[]) List<ShortageSupply> supplies,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Shortage;

  const Shortage._();

  factory Shortage.fromJson(Map<String, dynamic> json) => _$ShortageFromJson(json);

  /// «٣٠ كجم» — a quantity with the unit the server named it in, or the bare figure when a manual
  /// shortage carries no unit at all.
  String withUnit(String quantity) {
    final figure = quantity.grouped;

    return unitLabel == null ? figure : '$figure $unitLabel';
  }

  /// Whether anything is still owed. Parsed rather than compared to `'0.000'`, because the scale
  /// the server pads to is not this screen's business — and a figure it cannot read counts as
  /// outstanding, which is the safer of the two mistakes.
  bool get isOutstanding => (double.tryParse(remainingQuantity) ?? 1) > 0;

  /// Whether a person may still move it. An empty list is the server saying «nothing from here».
  bool get canChangeStatus => availableTransitions.isNotEmpty;

  /// Whether the goods are owed to a customer through an order, rather than wanted by the shop.
  bool get isFromOrder => orderId != null;

  /// The order's code when the row carries the order, and the id when it carries only that.
  ///
  /// Null on a manual shortage, which is what draws «يدوي» instead — §٨ of the brief asks for
  /// «معرفة مصدر النقص», and the code is the whole of it.
  String? get orderCode => switch ((order, orderId)) {
    (final loaded?, _) => loaded.code,
    (null, final id?) => '$id',
    _ => null,
  };
}
