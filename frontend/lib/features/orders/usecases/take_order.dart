import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/orders/models/new_order.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// Takes an order for a customer already known.
///
/// **Why this is a use case and not a line in the Cubit**, exactly as with `SaveProduct`: every
/// numeric field on this form can arrive in Arabic-Indic digits — `٣٠٠` from a Libyan keyboard
/// — and every numeric rule on the server is ASCII-only. There is a quantity per line plus a
/// design fee and a discount, so converting them at the widgets would be one chance per field
/// to forget. They are converted here, once, in a file a test reaches without a widget tree.
///
/// **And two rules about money that must not live in a widget:**
///
/// * A design fee counts only when we drew the artwork. The field is hidden for the other two
///   sources, but a clerk who typed one and then changed the source would still be sending it.
/// * A discount nobody typed is *absent*, never `'0'`. `orders.discount` is enforced on the
///   value being above zero, so an empty box has to produce no key at all.
///
/// Nothing here adds anything up. `items_total`, `delivery_price` and `grand_total` are the
/// server's, and the only totals shown before saving say they are estimates.
class TakeOrder {
  const TakeOrder(this._repository);

  final OrderRepository _repository;

  /// [customerId] comes from the screen this form was opened inside, never from a field: an
  /// order does not change hands, and the server ignores the customer on an update. Correcting
  /// the wrong one means cancelling the order and taking it again.
  Future<Either<Failure, Order>> call({
    required int customerId,
    required int cityId,
    required List<DraftOrderLine> lines,
    int? regionId,
    int? customerShopId,
    String designSource = 'none',
    String? designFee,
    String? discount,
    String? recipientName,
    String? recipientPhone,
    String? addressDetails,
    String? notes,
  }) {
    final fee = _number(designFee);

    return _repository.create(
      NewOrder(
        customerId: customerId,
        cityId: cityId,
        regionId: regionId,
        customerShopId: customerShopId,
        designSource: designSource,
        // Only our own work may be charged for — the same rule the server applies, applied here
        // so the request states what the clerk meant rather than relying on it being ignored.
        designFee: designSource == inHouseDesign ? fee : null,
        discount: _number(discount),
        recipientName: _text(recipientName),
        recipientPhone: _text(recipientPhone),
        addressDetails: _text(addressDetails),
        notes: _text(notes),
        items: [
          for (final (index, line) in lines.indexed)
            NewOrderItem(
              productId: line.productId,
              productVariantId: line.productVariantId,
              quantity: _number(line.quantity) ?? '',
              unitPrice: _number(line.unitPrice),
              notes: _text(line.notes),
              // The position on the form, so the invoice reads the way it was written.
              sortOrder: index,
            ),
        ],
      ),
    );
  }

  /// The `design_source` that may carry a fee. The other two are `none` and `customer`.
  static const String inHouseDesign = 'in_house';

  /// Arabic-Indic digits to ASCII, and a comma to a decimal point — and a blank box to nothing.
  ///
  /// `''` rather than `'0'` for an empty field is the point of the null: a zero discount and no
  /// discount are different requests.
  static String? _number(String? input) {
    final trimmed = input?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return Validators.toWesternDigits(trimmed).replaceAll(',', '.');
  }

  static String? _text(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// One line as the form holds it: the ids of what was picked, and the numbers still as text
/// because that is what was typed.
///
/// A plain class rather than a Freezed model — it never crosses the wire and is never stored.
/// It exists so [TakeOrder] takes one argument per line instead of five parallel lists.
class DraftOrderLine {
  const DraftOrderLine({
    required this.productId,
    required this.productVariantId,
    required this.quantity,
    this.unitPrice,
    this.notes,
  });

  final int productId;
  final int productVariantId;

  /// As typed — `'٣٠٠'`, `'1,5'`. Normalised on the way out, never at the widget.
  final String quantity;

  /// Filled in only for a product the catalogue prices «حسب الطلب». Empty for every other line,
  /// where naming a price would be an attempt to undercut the catalogue and the server ignores
  /// it anyway.
  final String? unitPrice;

  final String? notes;
}
