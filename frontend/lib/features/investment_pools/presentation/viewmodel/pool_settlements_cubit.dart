import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_pools/models/investment_settlement.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_settlements_cubit.freezed.dart';

/// التسوية — the position as it stands now, and every position somebody has signed before.
///
/// **The snapshot and the list are loaded together**, because the screen's whole job is to put
/// them side by side: «this is where the money is today, and here is what we said last time».
///
/// The figures shown before signing are the ones the signing then freezes. Deliberately the same
/// request the server answers from the same query — a second derivation in Dart is how a person
/// approves one position and the record keeps another.
class PoolSettlementsCubit extends Cubit<PoolSettlementsState> {
  PoolSettlementsCubit({
    required GetSettlementSnapshot getSnapshot,
    required GetSettlements getSettlements,
    required RecordSettlement recordSettlement,
  }) : _getSnapshot = getSnapshot,
       _getSettlements = getSettlements,
       _recordSettlement = recordSettlement,
       super(const PoolSettlementsState.loading());

  final GetSettlementSnapshot _getSnapshot;
  final GetSettlements _getSettlements;
  final RecordSettlement _recordSettlement;

  Future<void> load(int poolId) async {
    final snapshot = await _getSnapshot(poolId);

    if (isClosed) return;

    await snapshot.fold(
      (failure) async => emit(PoolSettlementsState.failure(failure)),
      (current) async {
        final history = await _getSettlements(poolId);

        if (isClosed) return;

        emit(
          PoolSettlementsState.loaded(
            snapshot: current,
            // An empty history is the ordinary state of a pool nobody has settled yet, so a
            // failure here reads the same as «none» rather than failing the screen the live
            // position is already on.
            settlements: history.fold(
              (_) => const <InvestmentSettlement>[],
              (value) => value,
            ),
          ),
        );
      },
    );
  }

  /// Freezes the position above and puts a name to it.
  ///
  /// **Moves nothing** — no wallet row, no stock movement, no period touched. Carries no figures
  /// and no period range: a settlement somebody could type the numbers into would approve a
  /// position the system does not hold, which is the very discrepancy the drift exists to catch.
  Future<Failure?> sign({
    required int poolId,
    String? settledOn,
    int? approvedBy,
    String? notes,
  }) async {
    final result = await _recordSettlement(
      poolId: poolId,
      settledOn: settledOn,
      approvedBy: approvedBy,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(poolId);

      return null;
    });
  }
}

@freezed
sealed class PoolSettlementsState with _$PoolSettlementsState {
  const factory PoolSettlementsState.loading() = PoolSettlementsLoading;

  const factory PoolSettlementsState.loaded({
    /// Where the money is **now**, derived on this read.
    required SettlementSnapshot snapshot,

    /// What has been signed before, newest first.
    @Default(<InvestmentSettlement>[]) List<InvestmentSettlement> settlements,
  }) = PoolSettlementsLoaded;

  const factory PoolSettlementsState.failure(Failure failure) =
      PoolSettlementsFailure;
}
