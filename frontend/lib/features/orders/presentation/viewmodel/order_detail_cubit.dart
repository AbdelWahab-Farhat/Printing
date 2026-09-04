import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
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
  }) : _orderId = orderId,
       _getOrder = getOrder,
       _addDesign = addDesign,
       _reviewDesign = reviewDesign,
       _reinstateOrder = reinstateOrder,
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
  Future<Failure?> reinstate({String? reason}) async {
    final order = state.order;
    if (order == null || state.isWorking) return null;

    emit(OrderDetailState.loaded(order: order, isWorking: true));

    final result = await _reinstateOrder(_orderId, reason: reason);

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
