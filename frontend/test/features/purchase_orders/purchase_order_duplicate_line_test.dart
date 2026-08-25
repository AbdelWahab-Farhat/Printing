import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The refusal the stock-item change made reachable, and where it has to land.
///
/// **An order carries one line per stock item.** Two products at one size are one pile of bags —
/// what separates «كيس شحن سادة 25*35» from «كيس شحن مطبوع 25*35» is printing, a cost rate rather
/// than a different material — so a buyer who used to raise those as two lines is now naming one
/// shelf twice. The server refuses it, and it refuses it *harder* than before: `distinct` used to
/// stand alone, and there is now a unique index (`purchase_order_items_one_line_per_item`) behind
/// it, so a request that slipped past the rule is refused by the database rather than quietly
/// stored.
///
/// The form blocks it before the save — see `_addLine`, which answers «هذا الصنف مضاف بالفعل» —
/// but a screen opened before somebody else re-filed a product's sizes can still reach the
/// server with it, so this is about the refusal that does arrive.
///
/// **Laravel addresses it at the offending index**: `items.1.stock_item_id`, which is not a thing
/// on screen — there is no box under that key, and the row it points at is numbered from zero in
/// a list a person reads from one. So the message has to be found by its shape and shown above
/// the list. A form that matched only the literal key `items` would swallow the one refusal that
/// says what is actually wrong, and the buyer would press «حفظ» on a form that appears to do
/// nothing.
///
/// Arrange - Act - Assert throughout.
void main() {
  SavePurchaseOrderState refusedWith(Map<String, List<String>> fieldErrors) =>
      SavePurchaseOrderState.failure(
        Failure.server(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: fieldErrors,
        ),
      );

  test('the duplicate-shelf refusal reaches the screen, index and all', () {
    // Arrange — `StorePurchaseOrderRequest`'s own wording, at the key it really arrives under.
    final state = refusedWith({
      'items.1.stock_item_id': ['لا يمكن تكرار نفس المادة أكثر من مرة في أمر الشراء'],
    });

    // Act
    final message = state.itemsError;

    // Assert — the server's Arabic, as sent. It is the only thing on the response that explains
    // why two lines a buyer sees as two different products are one line to the warehouse, and
    // replacing it with «حدث خطأ» would throw away the sentence the server took care to write.
    expect(message, 'لا يمكن تكرار نفس المادة أكثر من مرة في أمر الشراء');
  });

  test('a complaint about the list as a whole still wins over an indexed one', () {
    // Arrange — both arrive when an empty form is posted against a stale draft.
    final state = refusedWith({
      'items': ['يجب إضافة بند واحد على الأقل'],
      'items.0.stock_item_id': ['المادة المحددة غير موجودة'],
    });

    // Act
    final message = state.itemsError;

    // Assert — «add a line» is the instruction that can be acted on; a complaint about line
    // zero of a list with no lines in it is a sentence about something the person cannot see.
    expect(message, 'يجب إضافة بند واحد على الأقل');
  });

  test('a refusal shown above the list is not also toasted as unrendered', () {
    // Arrange
    final state = refusedWith({
      'items.1.stock_item_id': ['لا يمكن تكرار نفس المادة أكثر من مرة في أمر الشراء'],
    });

    // Act & Assert — the form already draws this one, and `hasUnrenderedErrors` is what decides
    // whether the *rest* goes to a toast. Counting it twice would put the same sentence on the
    // screen in two places, which reads as two problems.
    expect(state.hasUnrenderedErrors, isFalse);
  });

  test('a refusal with nowhere to sit is still not swallowed', () {
    // Arrange — a key no box on this form is keyed to.
    final state = refusedWith({
      'warehouse_id': ['مخزن الوجهة غير موجود'],
      'received_by': ['حقل غير معروف'],
    });

    // Act & Assert — `warehouse_id` has its own box, `received_by` has none, so something must
    // still reach the user. RULES.md §5: what has a box hangs under it, and what is left goes to
    // `context.showFailure`.
    expect(state.warehouseError, 'مخزن الوجهة غير موجود');
    expect(state.hasUnrenderedErrors, isTrue);
  });
}
