import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/usecases/get_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_detail_cubit.freezed.dart';
part 'order_detail_state.dart';

/// The ViewModel for one order.
///
/// **Every number on this screen comes from the server, including the balance.** What is owed
/// is the shop's arithmetic, not this app's — a total this app computed and a total on the
/// invoice would eventually disagree, and the customer would be looking at the wrong one.
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit({required this.orderId, required GetOrder get})
    : _get = get,
      super(const OrderDetailState.loading());

  final int orderId;
  final GetOrder _get;

  Future<void> load() async {
    emit(const OrderDetailState.loading());

    final result = await _get(orderId);

    if (isClosed) return;

    emit(result.fold(OrderDetailState.failure, OrderDetailState.loaded));
  }

  /// Re-reads without blanking the screen, for a pull-to-refresh on an order whose stage the
  /// customer is watching.
  Future<void> refresh() async {
    final loaded = _loaded;
    if (loaded == null) return;

    final result = await _get(orderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => loaded.copyWith(lastFailure: failure),
        OrderDetailState.loaded,
      ),
    );
  }

  OrderDetailLoaded? get _loaded => switch (state) {
    final OrderDetailLoaded loaded => loaded,
    _ => null,
  };
}
