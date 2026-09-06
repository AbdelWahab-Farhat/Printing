import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investors/models/order_investor_share.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_investor_shares_cubit.freezed.dart';

/// Who took money out of one order.
///
/// **Its own cubit rather than a field on the order**, because it is another context's answer
/// about the order and not part of it: the server publishes it behind `investors.view`, and an
/// order screen opened by somebody without that grant must render completely without ever asking.
class OrderInvestorSharesCubit extends Cubit<OrderInvestorSharesState> {
  OrderInvestorSharesCubit({required GetOrderInvestorShares getShares})
    : _getShares = getShares,
      super(const OrderInvestorSharesState.loading());

  final GetOrderInvestorShares _getShares;

  Future<void> load(int orderId) async {
    final result = await _getShares(orderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => OrderInvestorSharesState.failure(failure),
        (shares) => OrderInvestorSharesState.loaded(shares),
      ),
    );
  }
}

@freezed
sealed class OrderInvestorSharesState with _$OrderInvestorSharesState {
  const factory OrderInvestorSharesState.loading() = OrderInvestorSharesLoading;

  /// An empty list is the ordinary answer — «لا مستثمر في هذه الطلبية» — and the section draws
  /// nothing at all for it rather than an empty card.
  const factory OrderInvestorSharesState.loaded(List<OrderInvestorShare> shares) =
      OrderInvestorSharesLoaded;

  const factory OrderInvestorSharesState.failure(Failure failure) = OrderInvestorSharesFailure;
}
