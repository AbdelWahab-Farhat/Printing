import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_orders_cubit.freezed.dart';

/// شاشةُ الفترة الواحدة: طلبياتُها ومن أخذ منها.
class PeriodOrdersCubit extends Cubit<PeriodOrdersState> {
  PeriodOrdersCubit({required GetPeriodOrders getOrders})
    : _getOrders = getOrders,
      super(const PeriodOrdersState.loading());

  final GetPeriodOrders _getOrders;

  Future<void> load(int periodId) async {
    emit(const PeriodOrdersState.loading());

    final result = await _getOrders(periodId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => PeriodOrdersState.failure(failure),
        (loaded) => PeriodOrdersState.loaded(loaded),
      ),
    );
  }
}

@freezed
sealed class PeriodOrdersState with _$PeriodOrdersState {
  const factory PeriodOrdersState.loading() = PeriodOrdersLoading;

  const factory PeriodOrdersState.loaded(PeriodOrders held) = PeriodOrdersLoaded;

  const factory PeriodOrdersState.failure(Failure failure) = PeriodOrdersFailure;
}
