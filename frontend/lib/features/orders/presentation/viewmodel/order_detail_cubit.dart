// `show Either` rather than `hide Order`: dartz also exports a `State`, and only the one type
// this file names is worth taking.
import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_deposit_receipt.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/undo_order_step.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_detail_cubit.freezed.dart';
part 'order_detail_state.dart';

/// One order: what it says, and the artwork conversation on it.
///
/// **It does not move the order.** Changing a status belongs to [OrderStatusCubit], on the
/// screen that asks for whatever the move wants — this one takes the answer back through
/// [replace]. Two Cubits able to write the same status is the arrangement where one of them
/// ends up with an order the other has already changed.
///
/// **The designs it does own**, because they are not a move: versions come and go while the
/// order sits in «قيد التصميم», and approving one is what unlocks printing rather than being a
/// step of its own. Every one of them re-reads the order afterwards — approving a version
/// changes what the order may do next, and that answer is the server's.
///
/// Registered as a factory with the order's id as `param1`, so each screen gets its own — a
/// screen Cubit held as a singleton would close on the first order and leave every one after it
/// emitting into a dead stream.
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit({
    required int orderId,
    required GetOrder getOrder,
    required AddOrderDesign addDesign,
    required ReviewOrderDesign reviewDesign,
    required ReinstateOrder reinstateOrder,
    required UnsettleOrder unsettleOrder,
    required UndoOrderDelivery undoOrderDelivery,
    required DeleteOrder deleteOrder,
    required RestoreOrder restoreOrder,
    required ConfirmReadyMessage confirmReadyMessage,
    required ConfirmDepositReceipt confirmDepositReceipt,
  }) : _orderId = orderId,
       _getOrder = getOrder,
       _addDesign = addDesign,
       _reviewDesign = reviewDesign,
       _reinstateOrder = reinstateOrder,
       _unsettleOrder = unsettleOrder,
       _undoOrderDelivery = undoOrderDelivery,
       _deleteOrder = deleteOrder,
       _restoreOrder = restoreOrder,
       _confirmReadyMessage = confirmReadyMessage,
       _confirmDepositReceipt = confirmDepositReceipt,
       super(const OrderDetailState.loading());

  final int _orderId;
  final GetOrder _getOrder;
  final AddOrderDesign _addDesign;
  final ReviewOrderDesign _reviewDesign;

  /// **The one status this Cubit does write**, and the exception that proves the rule above it.
  /// Moving an order belongs to [OrderStatusCubit] because a move asks for whatever its
  /// destination wants; undoing a cancellation asks for nothing and offers no choice — the
  /// server reads where the order goes off its own timeline — so sending somebody to a screen
  /// that would draw one button and no fields is a screen for the sake of symmetry.
  final ReinstateOrder _reinstateOrder;

  /// The two other undos of one recorded move, held here for the reason [_reinstateOrder] is:
  /// no destination to choose, no fields beyond a reason, and the answer *is* the order.
  final UnsettleOrder _unsettleOrder;
  final UndoOrderDelivery _undoOrderDelivery;

  /// **The other two statuses this Cubit writes**, and they are not statuses at all — which is
  /// why they are here beside the reinstate rather than on the move screen. Neither offers a
  /// destination and neither asks for a field: the whole of each is a confirmation carrying the
  /// server's own preview of what it will do to the warehouse.
  final DeleteOrder _deleteOrder;
  final RestoreOrder _restoreOrder;

  /// **Not a status either, and not even about the bags.** «رسالة الجاهزية» records that an
  /// employee told the customer their order is ready — something that happened on somebody's own
  /// phone, which is why nothing derives it and why it lives here rather than on the move screen.
  final ConfirmReadyMessage _confirmReadyMessage;
  final ConfirmDepositReceipt _confirmDepositReceipt;

  Future<void> load() async {
    // Keeps whatever is on screen: this is also the pull-to-refresh handler, and blanking the
    // order to a spinner on every pull makes the gesture feel like leaving the screen.
    if (state.order == null) emit(const OrderDetailState.loading());

    final result = await _getOrder(_orderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => OrderDetailState.failure(failure: failure, order: state.order),
        (order) => OrderDetailState.loaded(order: order),
      ),
    );
  }

  /// Takes the order the move screen came back with.
  ///
  /// The response to a status change *is* the new order — its timeline has grown a row and, more
  /// importantly, its `available_transitions` are now a different set. Keeping what that screen
  /// was handed is one round trip instead of two, and there is no moment in between where this
  /// screen offers a move that has already stopped being legal.
  void replace(Order order) => emit(OrderDetailState.loaded(order: order));

  /// Puts one or more versions of the artwork on the order.
  ///
  /// Sent one at a time on purpose: the server allocates the version number, and «النسخة
  /// الثالثة» has to mean the file the conversation called the third. The first refusal stops
  /// the rest — whatever went before it is already on the order, which the re-read then shows.
  ///
  /// Answers with the failure rather than parking it in the state: there is no row on screen for
  /// it to attach to, and the screen shows a toast and moves on.
  Future<Failure?> addDesigns(List<int> customerDesignIds) async {
    final order = state.order;
    if (order == null || customerDesignIds.isEmpty) return null;

    emit(OrderDetailState.loaded(order: order, isWorking: true));

    for (final designId in customerDesignIds) {
      final result = await _addDesign(_orderId, customerDesignId: designId);
      if (isClosed) return null;

      if (result.isLeft()) {
        await load();

        return result.fold((failure) => failure, (_) => null);
      }
    }

    await load();

    return null;
  }

  /// Undoes a cancellation made by mistake, putting the order back where it stood.
  ///
  /// **Answers with the failure rather than parking it in the state**, like [addDesigns]: the
  /// order underneath is still perfectly drawable, and the screen has a snackbar for the
  /// server's sentence.
  ///
  /// The order comes back changed in more than its status — it is no longer final, its
  /// `available_transitions` are a real list again, and the cancellation banner is gone — so the
  /// response replaces what is on screen rather than being followed by a re-read.
  Future<Failure?> reinstate({String? reason}) =>
      _undo(() => _reinstateOrder(_orderId, reason: reason));

  /// «تراجع عن التسوية» — back to «تم الاستلام», so money on the order can be corrected.
  Future<Failure?> unsettle({required String reason}) =>
      _undo(() => _unsettleOrder(_orderId, reason: reason));

  /// «تراجع عن التسليم» — back to wherever the order was delivered from.
  Future<Failure?> undoDelivery({required String reason}) =>
      _undo(() => _undoOrderDelivery(_orderId, reason: reason));

  /// The shape the three undos share: spin, send, and put the answer on screen — or the order as
  /// it was, beside the failure, when the server refuses.
  Future<Failure?> _undo(Future<Either<Failure, Order>> Function() send) async {
    final order = state.order;
    if (order == null || state.isWorking) return null;

    emit(OrderDetailState.loaded(order: order, isWorking: true));

    final result = await send();

    if (isClosed) return null;

    return result.fold(
      (failure) {
        // Back to the order exactly as it was: nothing about it changed, and leaving the screen
        // spinning over a refusal is how a tap looks like it worked.
        emit(OrderDetailState.loaded(order: order));

        return failure;
      },
      (updated) {
        emit(OrderDetailState.loaded(order: updated));

        return null;
      },
    );
  }

  /// Archives the order, and keeps it on screen.
  ///
  /// **The screen does not close, and that is the point of the response being the order.** What
  /// comes back is the same order, trashed: `deleted_at` stamped, `available_transitions` and
  /// `progress` gone — so «تغيير الحالة» disappears from the dial on its own, «استعادة» takes
  /// the place of «حذف», and somebody who pressed it by mistake can undo it without going and
  /// finding it in الأرشيف first. The list behind is handed the same row and drops it.
  ///
  /// **Answers with the failure rather than parking it in the state**, exactly as [reinstate]
  /// does — and this one has more to say than most: «عليها مبلغ مدفوع» and «لها طرد مفتوح لدى
  /// نورس» each name the thing to do first, and neither could be written here without this app
  /// holding a copy of a ledger and of a parcel's state at the carrier.
  Future<Failure?> archive() => _write(() => _deleteOrder(_orderId));

  /// Puts the order back in the shop — **with its stock deducted again**.
  ///
  /// The order comes back live, so this screen redraws as an ordinary order: its transitions are
  /// a real list once more and its `stock_effect` flips to the delete's preview. Nothing is
  /// re-read afterwards for the reason [reinstate] gives — the response *is* the answer, and a
  /// second GET would only be a chance for the two to disagree.
  ///
  /// The refusals worth naming: a shelf that no longer holds enough, and a warehouse retired
  /// since the order left it. Both are the server's own sentences, and the second is the reason
  /// it checks explicitly — an app left to infer it would report «كل المقاسات صفر» about a store
  /// that simply no longer exists.
  Future<Failure?> restore() => _write(() => _restoreOrder(_orderId));

  /// Records that the customer was told the order is ready — or takes that back.
  ///
  /// **The switch follows the server, never the tap.** The order that comes back carries the
  /// stamp and the name behind it, neither of which this app can invent, so the row redraws from
  /// the answer; a refusal leaves the switch exactly where it was, which is [_write]'s whole
  /// shape. Nothing is re-read afterwards, for the reason [reinstate] gives.
  Future<Failure?> confirmReadyMessage({required bool sent}) =>
      _write(() => _confirmReadyMessage(_orderId, sent: sent));

  /// Records that the عربون actually arrived — or takes that back.
  ///
  /// The same shape as [confirmReadyMessage] above, and for the same reasons: the order that
  /// comes back carries the stamp and the name, a refusal leaves the switch where it was, and
  /// nothing is re-read afterwards.
  ///
  /// **Whether it may be called at all is the order's answer, not this cubit's.** The server
  /// folds the grant and the «somebody else must confirm it» rule into `canConfirmDeposit`, so
  /// the screen greys the switch from the order it is already holding.
  Future<Failure?> confirmDepositReceipt({required bool received}) =>
      _write(() => _confirmDepositReceipt(_orderId, received: received));

  /// Reads the order again for the one thing this app cannot work out for itself: the server's
  /// preview of what «حذف» — or «استعادة» — is about to do.
  ///
  /// **Needed because `stock_effect` does not survive a [replace].** It travels with the show,
  /// the destroy and the restore responses alone; the order a status change answers with has no
  /// preview on it, and this screen keeps that order rather than re-reading. So the block simply
  /// goes missing mid-visit, and the confirmation cannot be drawn without it — §٧ has the whole
  /// argument for why not one word of that dialog may be composed here.
  ///
  /// **A request, and it is the exception the repository rule allows.** «Lists patch, they do
  /// not refresh» permits one when the app genuinely cannot know the answer, and this is that
  /// case: the preview is derived from the movement ledger, line by line, and no arithmetic over
  /// what is on screen reconstructs it. The rejected alternative was keeping the last preview
  /// across a [replace] — cheaper, and wrong: a move into «جاهزة» is exactly what draws the
  /// stock, so the kept copy would promise «لا يتحرّك شيء» about an order that now has three
  /// hundred bags off the shelf, which is the one thing §٧ exists to prevent.
  ///
  /// **Answers with the failure rather than parking it**, like every other write here — and for
  /// a second reason of its own: a failure in the state is toasted by the screen's own listener,
  /// so parking it would tell the reader the same thing twice.
  Future<Failure?> refreshStockEffect() => _write(() => _getOrder(_orderId));

  /// The shape all three of those share: mark the screen busy, send, and either put the order
  /// back exactly as it was or replace it with what the server answered.
  ///
  /// Written once because they differ only in which call they make. A refusal must leave the
  /// screen showing the order it was showing — a screen left spinning over a refusal is how a
  /// tap comes to look like it worked.
  ///
  /// **The call is passed unstarted, and that is the whole of it.** This took the `Future`
  /// itself once, which meant Dart evaluated `_deleteOrder(id)` at the call site: the DELETE was
  /// on the wire before `isWorking` was ever read, so a double tap sent two of them, the second
  /// answer was dropped on the floor and the screen reported success over a request nobody
  /// looked at. A callback makes the guard mean what it says.
  Future<Failure?> _write(Future<Either<Failure, Order>> Function() send) async {
    final order = state.order;
    if (order == null || state.isWorking) return null;

    emit(OrderDetailState.loaded(order: order, isWorking: true));

    final result = await send();

    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(OrderDetailState.loaded(order: order));

        return failure;
      },
      (updated) {
        emit(OrderDetailState.loaded(order: updated));

        return null;
      },
    );
  }

  /// Approves a version, or turns it down with the sentence why.
  ///
  /// Re-reads afterwards for the reason approving exists at all: an approved version is what
  /// lets the order be printed, so `available_transitions` is a different list one moment later
  /// — and it is the server's to say, not this app's to infer.
  Future<Failure?> reviewDesign(
    int designId, {
    required bool isApproved,
    String? rejectionReason,
  }) async {
    final order = state.order;
    if (order == null) return null;

    emit(OrderDetailState.loaded(order: order, isWorking: true));

    final result = await _reviewDesign(
      _orderId,
      designId,
      isApproved: isApproved,
      rejectionReason: rejectionReason,
    );

    if (isClosed) return null;

    await load();

    return result.fold((failure) => failure, (_) => null);
  }
}
