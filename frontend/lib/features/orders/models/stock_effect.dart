import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_effect.freezed.dart';
part 'stock_effect.g.dart';

/// Which way the goods are about to move — and «لا يتحرّك شيء» is one of the answers.
///
/// **Read to decide how loudly the dialog reads, never to write its sentences.** The Arabic is
/// [StockEffect.warning] and [StockEffect.note], both the server's; this enum only says whether
/// the confirmation is about the warehouse at all, so a preview that moves nothing does not
/// borrow the red panel from one that empties a shelf.
enum StockEffectKind {
  /// Deleting the order puts back what it drew. `returnToShelf` rather than `return`, which is
  /// a Dart keyword — the wire value is the server's one word and stays it.
  @JsonValue('return')
  returnToShelf,

  /// Restoring it draws the goods again — **at today's cost**, which is what [StockEffect.note]
  /// is for. See §١ of ORDER-DELETE-AND-ARCHIVE.md: a restore claims the order should never
  /// have left, so it has to leave with its stock deducted, and the price of that is a
  /// different `total_cogs` from the one it went away with.
  @JsonValue('rededuct')
  rededuct,

  /// Nothing moves. An order whose stock a cancellation already put back, or one that never
  /// reached a shelf at all.
  @JsonValue('none')
  none,

  /// A kind this build has never heard of. The same forward compatibility
  /// `OrderStatus.unknown` buys the list: the sentence beside it is still the server's, and it
  /// is still shown — refusing to parse a payload because a fourth kind appeared would take the
  /// warning off a screen whose whole job is to carry it.
  unknown,
}

/// One thing that moves, as the server named it.
///
/// **The three fields are text, including the quantity.** «300» is what the preview says, in
/// the unit beside it; parsing it into a number here would be this app deciding how to print a
/// figure the server already printed — and money and quantities are strings everywhere else in
/// this model for the same reason.
@freezed
abstract class StockEffectLine with _$StockEffectLine {
  const factory StockEffectLine({
    required String label,
    required String quantity,
    required String unit,
  }) = _StockEffectLine;

  factory StockEffectLine.fromJson(Map<String, dynamic> json) =>
      _$StockEffectLineFromJson(json);
}

/// What pressing «حذف» — or «استعادة» — is about to do to the warehouse, written by the server.
///
/// **The precedent is `TransitionFields::deductionPreview()`, and so are both of its rules.**
/// That one builds an Arabic multi-line preview and hands it over as a `hint`, and its comment
/// says why: a hint rather than a field, so it reaches every build without a release; and it
/// cannot drift from what `DeductOrderStock` will do, because the preview and the action read
/// the same `OrderItem::producedQuantity()`. This inherits both — which is exactly why there is
/// no `switch (kind)` in this app turning a code into a sentence.
///
/// **It arrives on the show response and never on a list row.** Building it costs a read of the
/// movement ledger per line, and no row on a list is about to be deleted — see §٦ on the silent
/// N+1 the archive would otherwise carry.
///
/// **Derived from the ledger, not from `stock_deducted_at`.** That column is never cleared, so
/// an order that was cancelled — its goods already back on the shelf — and then deleted would
/// promise to return them a second time. The server owns that reasoning; this model only
/// carries the answer.
@freezed
abstract class StockEffect with _$StockEffect {
  const factory StockEffect({
    @JsonKey(unknownEnumValue: StockEffectKind.unknown) required StockEffectKind kind,

    /// The headline — «سيُعاد إلى المخزن ما خصمته هذه الطلبية:» or «سيُخصم من المخزن من جديد:»,
    /// and on a [StockEffectKind.none] a plain sentence saying no stock moves.
    required String warning,

    /// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
    /// missing key: the dialog draws the headline either way.
    @Default(<StockEffectLine>[]) List<StockEffectLine> lines,

    /// The second paragraph, which only the restore has: «وقد تختلف تكلفة الطلبية عمّا كانت…».
    String? note,
  }) = _StockEffect;

  const StockEffect._();

  factory StockEffect.fromJson(Map<String, dynamic> json) => _$StockEffectFromJson(json);

  /// Whether the warehouse is part of this at all.
  ///
  /// Read off [kind] rather than off `lines.isNotEmpty`: a kind this build has never heard of
  /// arrives as [StockEffectKind.unknown] with its lines intact, and «I do not know this move»
  /// is not «nothing happens».
  bool get movesStock => kind != StockEffectKind.none;
}
