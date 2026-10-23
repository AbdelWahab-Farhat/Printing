import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_sources_cubit.freezed.dart';

/// بوّابةٌ من بطاقة أرباحه، مفتوحةً صفحةً.
///
/// تُقرأ حين تُفتح الصفحة لا مع المستثمر: ثلاثُ قوائم في كل زيارةٍ لصفحته عملٌ لسؤالٍ يُسأل
/// أحياناً.
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
