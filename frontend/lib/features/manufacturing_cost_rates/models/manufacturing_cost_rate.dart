import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/vendors/models/stock_arrival.dart';

part 'manufacturing_cost_rate.freezed.dart';
part 'manufacturing_cost_rate.g.dart';

/// What a manufacturing cost is *for*, as the server's own enum.
///
/// **«خسارة تلف» is accepted by the API and never applied by it**, which is the one thing about
/// this list worth knowing. `ApplyManufacturingRates` walks only the kinds [isRateDriven] is true
/// for; a scrap loss is priced from the FIFO cost of the stock actually written off, never from a
/// rate somebody typed. The API will still store such a row, list it, and let it be edited — so
/// the form offers [offered] and the list renders whatever came back.
enum ManufacturingCostType {
  @JsonValue('labor')
  labor('labor', 'عمالة'),
  @JsonValue('machine_runtime')
  machineRuntime('machine_runtime', 'تشغيل آلة'),
  @JsonValue('overhead')
  overhead('overhead', 'مصاريف عامة'),
  @JsonValue('scrap_loss')
  scrapLoss('scrap_loss', 'خسارة تلف'),

  /// A kind this build has never heard of. Reached through `unknownEnumValue`, so one new case
  /// on the server does not turn the whole page into a parse failure.
  unknown('', '');

  const ManufacturingCostType(this.wire, this.label);

  final String wire;

  /// Mirrors the server's own `label()`. Held here because the filter has to name all four
  /// before a single rate has been loaded to read a `cost_type_label` off.
  final String label;

  /// Whether an order entering printing ever reads a rate of this kind.
  ///
  /// **Only [scrapLoss] is knowingly not applied**, and the screen says so with «لا يُطبَّق».
  /// Written as that one exclusion rather than as a list of the three that *are* applied,
  /// because an allowlist answers `false` for [unknown] too — and [unknown] is a kind this
  /// build has never heard of, not one this build knows is never used. Labelling a cost type
  /// the server added last week as «لا يُطبَّق» states something nobody here can know.
  bool get isRateDriven => this != scrapLoss;

  static ManufacturingCostType fromWire(String? wire) =>
      values.firstWhere((type) => type.wire == wire, orElse: () => unknown);

  /// Everything a person may filter by. [unknown] is what the app *reads*, never what it offers.
  static List<ManufacturingCostType> get choices =>
      values.where((type) => type != unknown).toList(growable: false);

  /// Everything a person may *create* — [choices] without [scrapLoss], for the reason on the
  /// enum: a scrap-loss rate is a row that is stored and then never consulted.
  ///
  /// Built from [choices] rather than filtered on [isRateDriven], which reads like the same
  /// thing and is not: [unknown] is rate-driven as far as this build can tell, and a dropdown
  /// offering it would post a cost type the server has no case for.
  static List<ManufacturingCostType> get offered =>
      choices.where((type) => type != scrapLoss).toList(growable: false);
}

/// Which rung of the ladder a rate sits on.
///
/// **Three rungs, and a rate is on exactly one of them.** When an order enters printing the
/// server looks for an active rate against the line's size, then against the line's product,
/// then for the one with neither — and stops at the first it finds. There is no fourth answer:
/// a cost type with no applicable rate is skipped rather than charged as zero.
///
/// Derived from which of the two references came back, never sent: the wire carries
/// `product_id` and `product_variant_id`, and the database refuses a row that sets both.
enum RateScope {
  standard('افتراضي', 'يُطبَّق على كل ما لا معدل أخص منه'),
  product('منتج بأكمله', 'يُطبَّق على كل مقاسات هذا المنتج'),
  variant('مقاس واحد', 'يُطبَّق على هذا المقاس وحده');

  const RateScope(this.label, this.note);

  /// What the rung is called on a chip — «افتراضي», «منتج بأكمله», «مقاس واحد».
  final String label;

  /// The sentence under the chip. The ladder is the whole point of this screen, and a rung
  /// nobody explained is a rate somebody will pin to the wrong thing.
  final String note;
}

/// معدل تكلفة تصنيع — what one unit of work costs, before anybody has done it.
///
/// These are the standing prices the workshop charges itself: an hour of labour, a run of the
/// machine, the overhead a job carries. **They are read once, when an order first enters
/// printing**, and the amount they produce is snapshotted onto the order's cost entries — so
/// editing a rate never restates an order that already went through, and stopping one only stops
/// it applying from that point on.
///
/// Mirrors `ManufacturingCostRateResource.php`.
@freezed
abstract class ManufacturingCostRate with _$ManufacturingCostRate {
  const factory ManufacturingCostRate({
    required int id,

    /// The product this rate is pinned to, or null when it is not on that rung.
    ///
    /// **Always present as a key**, because every endpoint eager-loads the relation: `null`
    /// means «this rate is not about a particular product», never «the server did not send it».
    /// The shape is the id-and-name the API flattens a reference into everywhere else, so it is
    /// the same class.
    ArrivalRef? product,

    /// The size this rate is pinned to. Null on the other two rungs, for the same reason.
    @JsonKey(name: 'product_variant') RateVariant? productVariant,

    @JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown)
    required ManufacturingCostType costType,

    /// The Arabic the server chose. Rendered as-is wherever *this* rate is on screen, so a kind
    /// added on the server still reads correctly here.
    @JsonKey(name: 'cost_type_label') required String costTypeLabel,

    /// What one unit costs — `'3.500'`, as the server stored it.
    ///
    /// **A `String`, like every other amount in this app.** It is a decimal the server sent with
    /// exactly three places, and parsing it into a `double` to show it is how `0.850` reaches a
    /// screen as `0.8500000000000001`.
    @JsonKey(name: 'rate_per_unit') required String ratePerUnit,

    /// Whether the rate is still consulted. A stopped rate is skipped when the ladder is walked,
    /// which lets the rung below it answer instead — it does not shadow.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    String? notes,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ManufacturingCostRate;

  const ManufacturingCostRate._();

  factory ManufacturingCostRate.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingCostRateFromJson(json);

  /// Which rung this rate is on, read off the two references rather than stored.
  RateScope get scope {
    if (productVariant != null) return RateScope.variant;
    if (product != null) return RateScope.product;

    return RateScope.standard;
  }

  /// What the row says it applies to.
  ///
  /// **A row that does not name its rung is unreadable**: three rates for «عمالة» differing only
  /// in what they are pinned to look like three copies of the same line otherwise.
  ///
  /// The size is prefixed with «مقاس» because the server sends the bare dimensions — `'25*35'`
  /// with no product beside them — and a lone measurement in a list of names reads as noise.
  String get scopeLabel => switch (scope) {
    RateScope.variant => 'مقاس ${productVariant!.label}',
    RateScope.product => product!.name,
    RateScope.standard => RateScope.standard.label,
  };

  /// The id of whatever this rate is pinned to, or null on the default rung. What the form
  /// reopens on.
  int? get scopeId => productVariant?.id ?? product?.id;

  /// `'3.500'` reads as a rate to a database and as noise to a person: `'3.5'`.
  String get rateLabel => groupedDecimal(ratePerUnit);
}

/// The size a rate is pinned to, as this endpoint flattens it.
///
/// **It does not say which product the size belongs to** — no `product_id`, no product name —
/// so a variant-tier row can name «25*35» and nothing more. That is the whole payload, and
/// guessing the product from a second request would be a screen that is right most of the time.
@freezed
abstract class RateVariant with _$RateVariant {
  const factory RateVariant({required int id, required String label}) = _RateVariant;

  factory RateVariant.fromJson(Map<String, dynamic> json) => _$RateVariantFromJson(json);
}
