import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';

part 'order_invoice_state.dart';
part 'order_invoice_cubit.freezed.dart';

/// Editing one order's lines and its discount.
///
/// Seeded from the order the screen already has rather than re-fetching it: the sheet opens on
/// top of a page that just loaded, and a spinner over data the user is looking at is a round
/// trip spent to show them what they can already see.
///
/// **Quantities are held as typed.** Not parsed on every keystroke — a half-typed `3.` is not a
/// number and normalising it mid-edit would fight the person typing. Validity is asked at the
/// end, and the conversion from Arabic-Indic digits happens once, on the way out.
class OrderInvoiceCubit extends Cubit<OrderInvoiceState> {
  OrderInvoiceCubit({required Order order, required UpdateOrderInvoice updateInvoice})
    : _updateInvoice = updateInvoice,
      super(
        OrderInvoiceState(
          orderId: order.id,
          lines: [
            for (final item in order.items ?? const <OrderItem>[])
              InvoiceLine(
                id: item.id,
                productId: item.productId,
                variantId: item.productVariantId,
                productName: item.productName,
                variantLabel: item.variantLabel,
                pricingUnitLabel: item.pricingUnitLabel,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
              ),
          ],
          discount: order.discount,
          designFee: order.designFee,
          deliveryPrice: order.deliveryPrice,
          cityId: order.cityId,
          cityName: order.cityName,
          regionId: order.regionId,
          regionName: order.regionName,
          recipientPhone: order.recipientPhone,
          linesAreEditable: order.itemsAreEditable,
          destinationIsEditable: order.destinationIsEditable,
        ),
      );

  final UpdateOrderInvoice _updateInvoice;

  void setQuantity(int lineId, String quantity) {
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.id == lineId) line.copyWith(quantity: quantity) else line,
        ],
        isDirty: true,
        // Cleared as soon as the user changes something: a refusal from the last attempt sitting
        // over a form they have since edited is stale advice.
        failure: null,
      ),
    );
  }

  void remove(int lineId) {
    // The last line is never removed — an order with nothing on it is refused by the server, and
    // the button that would do it is hidden. Guarded here too, because a Cubit that only holds
    // when a widget remembers to is not holding.
    if (state.lines.length <= 1) return;

    emit(
      state.copyWith(
        lines: state.lines.where((line) => line.id != lineId).toList(growable: false),
        isDirty: true,
        failure: null,
      ),
    );
  }

  void setDiscount(String discount) {
    emit(state.copyWith(discount: discount, isDirty: true, failure: null));
  }

  /// Moves the order to another city.
  ///
  /// **The region is cleared with it, always.** A region belongs to one city, so carrying the
  /// old one across would send the server a neighbourhood from somewhere else — which it
  /// refuses, correctly, with a message about a field the user never touched.
  void setCity({required int id, required String name}) {
    if (id == state.cityId) return;

    emit(
      state.copyWith(
        cityId: id,
        cityName: name,
        regionId: null,
        regionName: null,
        isDirty: true,
        failure: null,
      ),
    );
  }

  void setRegion({required int id, required String name}) {
    emit(
      state.copyWith(regionId: id, regionName: name, isDirty: true, failure: null),
    );
  }

  /// Corrects the number the courier rings.
  ///
  /// Emptied to nothing rather than to `''`: «there is no second number» is what the server
  /// stores as null, and an empty string would be a phone number of no digits.
  void setRecipientPhone(String phone) {
    final trimmed = phone.trim();

    emit(
      state.copyWith(
        recipientPhone: trimmed.isEmpty ? null : trimmed,
        isDirty: true,
        failure: null,
      ),
    );
  }

  Future<void> save() async {
    if (!state.isValid || state.isSaving) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final result = await _updateInvoice(
      state.orderId,
      // Omitted entirely when the lines are shut: `items` absent means "leave them alone",
      // which is the only way to save an address change on an order past «جاهزة».
      lines: state.linesAreEditable
          ? [
              for (final line in state.lines)
                InvoiceLineUpdate(
                  productId: line.productId,
                  variantId: line.variantId,
                  quantity: _ascii(line.quantity),
                ),
            ]
          : null,
      discount: state.linesAreEditable ? _ascii(state.discount) : null,
      cityId: state.cityId,
      regionId: state.regionId,
      // Sent only when it may be changed. On an order out for delivery the server refuses a
      // *different* number, and this screen has no business offering one it would refuse.
      recipientPhone: state.destinationIsEditable ? (number: state.recipientPhone) : null,
    );

    if (isClosed) return;

    emit(
      result.fold(
        // The form stays exactly as it was: a 422 naming a quantity is advice about the thing
        // still on screen, and rebuilding the sheet would throw away what it is advising on.
        (failure) => state.copyWith(isSaving: false, failure: failure),
        (_) => state.copyWith(isSaving: false, isSaved: true),
      ),
    );
  }
}
