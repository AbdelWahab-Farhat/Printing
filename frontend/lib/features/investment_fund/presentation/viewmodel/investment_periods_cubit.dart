import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_periods_cubit.freezed.dart';

/// سجلُّ الفترات — ما أُقفل وبكم، وما هو مفتوح.
class InvestmentPeriodsCubit extends Cubit<InvestmentPeriodsState> {
  InvestmentPeriodsCubit({required GetFundPeriods getPeriods})
    : _getPeriods = getPeriods,
      super(const InvestmentPeriodsState.loading());

  final GetFundPeriods _getPeriods;

  Future<void> load() async {
    emit(const InvestmentPeriodsState.loading());

    final result = await _getPeriods();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => InvestmentPeriodsState.failure(failure),
        (periods) => InvestmentPeriodsState.loaded(periods: periods),
      ),
    );
  }
}

@freezed
sealed class InvestmentPeriodsState with _$InvestmentPeriodsState {
  const factory InvestmentPeriodsState.loading() = InvestmentPeriodsLoading;

  const factory InvestmentPeriodsState.loaded({required List<FundPeriod> periods}) =
      InvestmentPeriodsLoaded;

  const factory InvestmentPeriodsState.failure(Failure failure) = InvestmentPeriodsFailure;
}
