/// What is missing from one order line, in both the units that have a claim on it.
///
/// **Two numbers travel together because they are written together.** [quantity] is what comes
/// off the invoice, in the unit the customer was billed in; [warehouseQuantity] is what
/// «النواقص» will chase and the warehouse will receive, in the unit the shelf is counted in.
/// Neither can be computed from the other — bags weighed together have no per-bag weight — so
/// they are stated as a pair by whoever declares the shortage.
///
/// **[warehouseQuantity] null means «the same number»**, which is the ordinary case: most sizes
/// are stocked in the unit they are sold in, and the wire sends a bare figure for them exactly as
/// it always did. Sending one where the units agree is refused by the server for the same reason
/// a warehouse on an unstockable shortage is: it claims a conversion that did not happen.
///
/// In `models/` rather than beside the sheet that fills it, so the repository can name it without
/// importing presentation.
class LineShortageEntry {
  const LineShortageEntry({this.quantity, this.warehouseQuantity});

  final String? quantity;
  final String? warehouseQuantity;

  /// Nothing missing from this line — the value an emptied box means, and the one that puts the
  /// money back on the invoice.
  bool get isNothing => quantity == null || quantity!.trim().isEmpty;
}
