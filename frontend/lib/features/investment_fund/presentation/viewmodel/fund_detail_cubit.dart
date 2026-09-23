import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_detail_cubit.freezed.dart';

/// شاشةُ بندٍ واحد من بنود اللوحة — تُقرأ مرّةً وتُعرض.
///
/// **صنفٌ واحد لثلاث شاشات** — الرفُّ، والبضاعةُ الخارجة، والأرباحُ المستحقّة — لأنها لا تفترق
/// إلا فيما تقرؤه: طلبٌ واحد، وحالاتٌ ثلاث، وسحبٌ للتحديث. ثلاثُ نسخٍ منه كانت ستعني إصلاحاً
/// يُطبَّق في واحدةٍ ويُنسى في أختيها.
class FundDetailCubit<T> extends Cubit<FundDetailState<T>> {
  FundDetailCubit(this._fetch) : super(FundDetailState<T>.loading());

  final Future<Either<Failure, T>> Function() _fetch;

  Future<void> load() async {
    emit(FundDetailState<T>.loading());

    final result = await _fetch();

    if (isClosed) return;

    emit(result.fold(FundDetailState<T>.failure, FundDetailState<T>.loaded));
  }
}

@freezed
sealed class FundDetailState<T> with _$FundDetailState<T> {
  const factory FundDetailState.loading() = FundDetailLoading<T>;

  const factory FundDetailState.loaded(T value) = FundDetailLoaded<T>;

  const factory FundDetailState.failure(Failure failure) = FundDetailFailure<T>;
}
