import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_effect.freezed.dart';
part 'stock_effect.g.dart';

/// Which way the goods are about to move — and «لا يتحرّك شيء» is one of the answers.
///
/// **Read to decide how loudly the dialog reads, never to write its sentences.** The Arabic is
/// [WarehouseEffect.warning] and [WarehouseEffect.note], both the server's; this enum only says
/// whether the confirmation is about the warehouse at all, so a preview that moves nothing does
/// not borrow the red panel from one that empties a shelf.
enum StockEffectKind {
  /// Deleting the order puts back what it drew. `returnToShelf` rather than `return`, which is
  /// a Dart keyword — the wire value is the server's one word and stays it.
  @JsonValue('return')
  returnToShelf,

  /// Restoring it draws the goods again — **at today's cost**, which is what
  /// [WarehouseEffect.note] is for. See §١ of ORDER-DELETE-AND-ARCHIVE.md: a restore claims the
  /// order should never have left, so it has to leave with its stock deducted, and the price of
  /// that is a different `total_cogs` from the one it went away with.
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

/// Which way the money is about to move.
///
/// Two kinds, because the two directions are not symmetrical and §٢٫١ is why: a delete **writes
/// reversal entries** for everything live on the order, and a restore **does not write them
/// back**. So one of these is a warning about something that is about to happen, and the other
/// is a warning about something that already did and is not going to be undone.
enum MoneyEffectKind {
  /// The delete is about to reverse what was collected. Lines carry the amounts.
  @JsonValue('reverse')
  reverse,

  /// This archived order already had its money reversed, and the restore will not bring it
  /// back. No lines — see [MoneyEffect.lines].
  @JsonValue('reversed')
  reversed,

  /// As [StockEffectKind.unknown], and for the same reason.
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

/// One kind of money that is about to be reversed, summed — «مدفوع»، «إعفاء»، «تحصيل مندوب».
///
/// Text for the same reason the quantity is: the server rounded it and named its currency, and
/// a second opinion here is how «١٬٢٠٠٫٠٠» and «1200.0» end up on two screens of one app.
@freezed
abstract class MoneyEffectLine with _$MoneyEffectLine {
  const factory MoneyEffectLine({
    required String label,
    required String amount,
    required String currency,
  }) = _MoneyEffectLine;

  factory MoneyEffectLine.fromJson(Map<String, dynamic> json) =>
      _$MoneyEffectLineFromJson(json);
}

/// What pressing «حذف» is about to do to the ledger — the heavier half of the confirmation.
///
/// **Its own section, and drawn first**, because §٢٫١ made the delete reverse the money rather
/// than refuse to run: one button can now undo a cash collection, which is a bigger thing than
/// moving bags between shelves, and a reader who meets the stock list first has already started
/// deciding by the time the money reaches them.
///
/// **Null when there is nothing to say**, never an empty section. §٧٫١ is explicit: an order
/// with no live entry gets no money block at all, not a block saying «لا يوجد» — a heading that
/// resolves to nothing is a heading somebody read for no reason.
@freezed
abstract class MoneyEffect with _$MoneyEffect {
  const factory MoneyEffect({
    @JsonKey(unknownEnumValue: MoneyEffectKind.unknown) required MoneyEffectKind kind,

    /// «سيُعكس ما قُبض على هذه الطلبية:» on a delete, and on a restore the sentence saying the
    /// reversed payments are not coming back.
    required String warning,

    /// One line per kind on a [MoneyEffectKind.reverse]. **Empty on
    /// [MoneyEffectKind.reversed]**, and deliberately: amounts belong to the confirmation that
    /// *did* the reversing, where they could still change somebody's mind. On the way back they
    /// would only be a bill for a decision already taken.
    @Default(<MoneyEffectLine>[]) List<MoneyEffectLine> lines,

    /// The sentence that is the point of the whole section: a restore does **not** put the
    /// payments back, so the money has to be re-entered by hand if it really was taken. Without
    /// it a reader takes «سيُعكس» for «and it can be undone», which is the one wrong idea this
    /// dialog exists to prevent.
    String? note,
  }) = _MoneyEffect;

  factory MoneyEffect.fromJson(Map<String, dynamic> json) => _$MoneyEffectFromJson(json);
}

/// What it is about to do to the warehouse, written by the server.
///
/// **The precedent is `TransitionFields::deductionPreview()`, and so are both of its rules.**
/// That one builds an Arabic multi-line preview and hands it over as a `hint`, and its comment
/// says why: a hint rather than a field, so it reaches every build without a release; and it
/// cannot drift from what `DeductOrderStock` will do, because the preview and the action read
/// the same `OrderItem::producedQuantity()`. This inherits both — which is exactly why there is
/// no `switch (kind)` in this app turning a code into a sentence.
///
/// **Derived from the ledger, not from `stock_deducted_at`.** That column is never cleared, so
/// an order that was cancelled — its goods already back on the shelf — and then deleted would
/// promise to return them a second time. The server owns that reasoning; this model only
/// carries the answer.
@freezed
abstract class WarehouseEffect with _$WarehouseEffect {
  const factory WarehouseEffect({
    @JsonKey(unknownEnumValue: StockEffectKind.unknown) required StockEffectKind kind,

    /// The headline — «سيُعاد إلى المخزن ما خصمته هذه الطلبية:» or «سيُخصم من المخزن من جديد:»,
    /// and on a [StockEffectKind.none] a plain sentence saying no stock moves.
    required String warning,

    /// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
    /// missing key: the dialog draws the headline either way.
    @Default(<StockEffectLine>[]) List<StockEffectLine> lines,

    /// The second paragraph, which only the restore has: «وقد تختلف تكلفة الطلبية عمّا كانت…».
    String? note,
  }) = _WarehouseEffect;

  const WarehouseEffect._();

  factory WarehouseEffect.fromJson(Map<String, dynamic> json) =>
      _$WarehouseEffectFromJson(json);

  /// Whether the warehouse is part of this at all.
  ///
  /// Read off [kind] rather than off `lines.isNotEmpty`: a kind this build has never heard of
  /// arrives as [StockEffectKind.unknown] with its lines intact, and «I do not know this move»
  /// is not «nothing happens».
  bool get movesStock => kind != StockEffectKind.none;
}

/// The whole of what pressing «حذف» — or «استعادة» — is about to do, in the server's words.
///
/// **Two sections in one envelope rather than two keys on the order**, and §٧٫١ gives the
/// reason: the screen shows them together, so which comes first is a decision, and it is the
/// server's. `StockEffectPreview::for()` builds this array money-first literally so that the
/// order of the keys *is* the order on screen and no Dart file gets to re-rank them.
///
/// **It arrives on the show response and never on a list row.** Building it costs a read of the
/// movement ledger per line and a walk of the payment ledger, and no row on a list is about to
/// be deleted — see §٦ on the silent N+1 the archive would otherwise carry. That is also why
/// [Order.stockEffect] is null after a status move: the response that carried the moved order
/// was not a show. See `OrderDetailCubit.refreshStockEffect`.
@freezed
abstract class StockEffect with _$StockEffect {
  const factory StockEffect({
    /// The warehouse half. Always present — «لا يتحرّك شيء» is an answer, not an absence.
    required WarehouseEffect stock,

    /// The ledger half, or null when this order has no money to say anything about.
    MoneyEffect? money,
  }) = _StockEffect;

  const StockEffect._();

  factory StockEffect.fromJson(Map<String, dynamic> json) => _$StockEffectFromJson(json);

  /// Whether either half has something to warn about.
  ///
  /// Used to decide whether the dialog is a warning at all, not to decide what it says.
  bool get isLoud => money != null || stock.movesStock;
}
