import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_pools/models/capital_request.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/models/period_share.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_periods_cubit.freezed.dart';

/// A pool's periods, and the two irreversible buttons that live among them.
///
/// **The figures shown before a close are fetched, never computed here.** A close is an
/// irreversible payout, and the screen that asks somebody to press the button must print the same
/// arithmetic the ledger will then perform — a second implementation in Dart is exactly how a
/// person approves one figure and the server writes another.
class PoolPeriodsCubit extends Cubit<PoolPeriodsState> {
  PoolPeriodsCubit({
    required GetPoolPeriods getPeriods,
    required OpenInvestmentPeriod openPeriod,
    required GetPeriodFigures getFigures,
    required GetPeriodShares getShares,
    required CloseInvestmentPeriod closePeriod,
  }) : _getPeriods = getPeriods,
       _openPeriod = openPeriod,
       _getFigures = getFigures,
       _getShares = getShares,
       _closePeriod = closePeriod,
       super(const PoolPeriodsState.loading());

  final GetPoolPeriods _getPeriods;
  final OpenInvestmentPeriod _openPeriod;
  final GetPeriodFigures _getFigures;
  final GetPeriodShares _getShares;
  final CloseInvestmentPeriod _closePeriod;

  Future<void> load(int poolId) async {
    final result = await _getPeriods(poolId);

    if (isClosed) return;

    emit(
      result.fold(
        PoolPeriodsState.failure,
        (periods) => PoolPeriodsState.loaded(periods: periods),
      ),
    );
  }

  /// What the period has made so far, for the confirmation screen.
  ///
  /// Returned rather than emitted: the close sheet owns it, and putting it in the list's state
  /// would leave a stale set of figures sitting there after the sheet is dismissed.
  Future<Either<Failure, PeriodFigures>> figures(int periodId) =>
      _getFigures(periodId);

  /// Who got what in a closed period.
  ///
  /// Returned rather than emitted, like [figures]: the sheet that shows it owns it, and putting it
  /// in the list's state would leave one period's breakdown sitting there after the sheet closes.
  Future<Either<Failure, List<PeriodShare>>> shares(int periodId) =>
      _getShares(periodId);

  /// Opens the pool's next period and lets in the capital queued for the boundary.
  ///
  /// Returns what came in, because [PeriodOpened.short] names anybody whose wallet could no
  /// longer cover what he had asked for — his request stays pending and the period opens anyway,
  /// which somebody has to be told rather than left to notice.
  Future<Either<Failure, PeriodOpened>> openNext(int poolId) async {
    final result = await _openPeriod(poolId);

    if (isClosed) return result;

    if (result.isRight()) await load(poolId);

    return result;
  }

  /// **Irreversible.** Divides the period, releases profit into wallets where it can be
  /// withdrawn, pays whoever asked to leave, and opens the next one in the same breath.
  ///
  /// Refused by the server while a returned-goods question is unanswered, and that refusal is
  /// what the screen shows — the app does not duplicate the rule.
  // Named `closePeriod`, not `close`: `Cubit.close()` already exists, and shadowing it would make
  // «أقفل الفترة» tear down the ViewModel instead of paying anybody.
  Future<Failure?> closePeriod({
    required int poolId,
    required int periodId,
  }) async {
    final result = await _closePeriod(periodId);

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(poolId);

      return null;
    });
  }
}

@freezed
sealed class PoolPeriodsState with _$PoolPeriodsState {
  const factory PoolPeriodsState.loading() = PoolPeriodsLoading;

  const factory PoolPeriodsState.loaded({
    required List<InvestmentPeriod> periods,
  }) = PoolPeriodsLoaded;

  const factory PoolPeriodsState.failure(Failure failure) = PoolPeriodsFailure;
}
