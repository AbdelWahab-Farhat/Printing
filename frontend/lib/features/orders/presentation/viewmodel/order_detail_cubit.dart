import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/usecases/change_order_status.dart';
import 'package:printing/features/orders/usecases/get_order.dart';

part 'order_detail_state.dart';
part 'order_detail_cubit.freezed.dart';

/// One order, and the moves staff make on it.
///
/// Registered as a factory with the order's id as `param1`, so each screen gets its own — a
/// screen Cubit held as a singleton would close on the first order and leave every one after it
/// emitting into a dead stream.
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit({
    required int orderId,
    required GetOrder getOrder,
    required ChangeOrderStatus changeStatus,
  }) : _orderId = orderId,
       _getOrder = getOrder,
       _changeStatus = changeStatus,
       super(const OrderDetailState.loading());

  final int _orderId;
  final GetOrder _getOrder;
  final ChangeOrderStatus _changeStatus;

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

  /// Moves the order, and keeps the returned one.
  ///
  /// The response *is* the new order — its timeline has grown a row and, more importantly, its
  /// `available_transitions` are now a different set. Taking the server's answer rather than
  /// re-fetching is one round trip instead of two, and there is no moment in between where the
  /// screen offers a button that has already stopped being legal.
  ///
  /// Returns the updated order so the list behind can replace its row, or null if the move was
  /// refused — the caller shows the failure either way through the state.
  Future<Order?> move(OrderStatus status, {String? reason}) async {
    final current = state.order;
    if (current == null) return null;

    emit(OrderDetailState.loaded(order: current, isMoving: true));

    final result = await _changeStatus(_orderId, status: status, reason: reason);

    if (isClosed) return null;

    return result.fold<Order?>(
      (failure) {
        // The order stays: a refused move must leave the screen showing what it was showing,
        // with the server's own sentence over the top rather than an empty page.
        emit(OrderDetailState.failure(failure: failure, order: current));

        return null;
      },
      (updated) {
        emit(OrderDetailState.loaded(order: updated));

        return updated;
      },
    );
  }
}
