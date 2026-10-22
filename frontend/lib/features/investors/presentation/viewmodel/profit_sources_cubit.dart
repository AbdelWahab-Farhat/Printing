import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_sources_cubit.freezed.dart';

/// One gate of his profit card, opened in a sheet.
///
/// Read when the sheet opens rather than with the investor: three lists on every visit to the
/// page would be work for a question asked now and then.
class ProfitSourcesCubit extends Cubit<ProfitSourcesState> {
  ProfitSourcesCubit({required GetProfitSources getSources})
    : _getSources = getSources,
      super(const ProfitSourcesState.loading());

  final GetProfitSources _getSources;

  Future<void> load(int investorId, ProfitGate gate) async {
    emit(const ProfitSourcesState.loading());

    final result = await _getSources(investorId, gate);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => ProfitSourcesState.failure(failure),
        (sources) => ProfitSourcesState.loaded(sources),
      ),
    );
  }
}

@freezed
sealed class ProfitSourcesState with _$ProfitSourcesState {
  const factory ProfitSourcesState.loading() = ProfitSourcesLoading;

  const factory ProfitSourcesState.loaded(ProfitSources sources) = ProfitSourcesLoaded;

  const factory ProfitSourcesState.failure(Failure failure) = ProfitSourcesFailure;
}
