import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/usecases/take_order.dart';

part 'take_order_state.dart';
part 'take_order_cubit.freezed.dart';

/// The ViewModel behind «طلبية جديدة».
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext`.
///
/// **It holds no draft either**, the same as `SaveProductCubit`: the form owns its controllers,
/// because those are widget-lifecycle resources that must be disposed and a Cubit is not a
/// disposal mechanism. What this does hold is the one fact the form must not be able to change
/// — [customerId], taken from the screen the form was opened inside.
class TakeOrderCubit extends Cubit<TakeOrderState> {
  TakeOrderCubit({required TakeOrder takeOrder, required this.customerId})
    : _takeOrder = takeOrder,
      super(const TakeOrderState.initial());

  final TakeOrder _takeOrder;

  /// Whose order this is. Constructor-injected rather than passed to [submit], because an order
  /// never changes hands: the server reads `customer_id` on create and ignores it afterwards,
  /// so the only correction for the wrong one is to cancel the order and take it again. A form
  /// that cannot name a customer cannot name the wrong one.
  final int customerId;

  /// Sends the form.
  ///
  /// **A [Failure.network] here must not be retried blindly.** An order has no natural key, so
  /// a request that reached the server before the connection dropped leaves an order behind
  /// and a second POST is a second order with a second number — one that then has to be
  /// cancelled by hand, after somebody notices. The screen says so rather than offering a
  /// «أعد المحاولة» that can quietly duplicate a job of work.
  Future<void> submit({
    required int cityId,
    required List<DraftOrderLine> lines,
    int? regionId,
    int? customerShopId,
    String designSource = 'none',
    String? designFee,
    String? discount,
    String? recipientPhone,
    String? notes,
    List<int> designIds = const [],
  }) async {
    // Ignored rather than queued, for the reason above: a second tap while the first is in
    // flight is a second order.
    if (state.isSubmitting) return;

    // The server refuses this too — `OrderNeedsAtLeastOneItem` — but a request whose only
    // possible answer is a refusal is one nobody should have to wait for. The button is
    // disabled without a line; this is the half that is a rule rather than a suggestion.
    if (lines.isEmpty) return;

    emit(const TakeOrderState.submitting());

    final result = await _takeOrder(
      customerId: customerId,
      cityId: cityId,
      lines: lines,
      regionId: regionId,
      customerShopId: customerShopId,
      designSource: designSource,
      designFee: designFee,
      discount: discount,
      recipientPhone: recipientPhone,
      notes: notes,
      designIds: designIds,
    );

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold((f) => TakeOrderState.failure(f), (o) => TakeOrderState.success(o)));
  }

  /// Clears a previous refusal so an error under a field disappears as the user corrects it,
  /// rather than lingering until the next submit.
  void clearFailure() {
    if (state is TakeOrderFailure) emit(const TakeOrderState.initial());
  }
}
