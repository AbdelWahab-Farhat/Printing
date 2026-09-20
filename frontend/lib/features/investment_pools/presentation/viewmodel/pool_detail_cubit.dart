import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_pools/models/capital_request.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/models/pool_expense.dart';
import 'package:dayaa/features/investment_pools/models/returned_goods_question.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_detail_cubit.freezed.dart';

/// One pool: its shelves, its members, what it may spend, and what is holding its close up.
///
/// **Four reads, one screen, loaded together.** They are read together and go stale together —
/// answering a returned-goods question changes what the close screen may do, and capital arriving
/// changes what the pool may spend. Splitting them into four Cubits would mean four chances for
/// the screen to show a figure from before the last action.
class PoolDetailCubit extends Cubit<PoolDetailState> {
  PoolDetailCubit({
    required GetInvestmentPool getPool,
    required GetPoolDeployableCash getCash,
    required GetReturnedGoods getReturnedGoods,
    required AnswerReturnedGoods answerReturnedGoods,
    required RequestPoolCapital requestCapital,
    required CancelCapitalRequest cancelCapitalRequest,
    required GetCapitalRequests getCapitalRequests,
    required GetPoolExpenses getExpenses,
  }) : _getPool = getPool,
       _getCash = getCash,
       _getReturnedGoods = getReturnedGoods,
       _answerReturnedGoods = answerReturnedGoods,
       _requestCapital = requestCapital,
       _cancelCapitalRequest = cancelCapitalRequest,
       _getCapitalRequests = getCapitalRequests,
       _getExpenses = getExpenses,
       super(const PoolDetailState.loading());

  final GetInvestmentPool _getPool;
  final GetPoolDeployableCash _getCash;
  final GetReturnedGoods _getReturnedGoods;
  final AnswerReturnedGoods _answerReturnedGoods;
  final RequestPoolCapital _requestCapital;
  final CancelCapitalRequest _cancelCapitalRequest;
  final GetCapitalRequests _getCapitalRequests;
  final GetPoolExpenses _getExpenses;

  Future<void> load(int id) async {
    final result = await _getPool(id);

    if (isClosed) return;

    await result.fold(
      (failure) async => emit(PoolDetailState.failure(failure)),
      (pool) async {
        // The three companion reads. A failure in any of them leaves that section empty rather
        // than failing the screen: a pool whose cash could not be read is still a pool somebody
        // may want to look at, and its name and members are already in hand.
        final cash = await _getCash(id);
        final questions = await _getReturnedGoods(poolId: id, onlyOpen: true);
        final requests = await _getCapitalRequests(id);
        final expenses = await _getExpenses(id);

        if (isClosed) return;

        emit(
          PoolDetailState.loaded(
            pool: pool,
            cash: cash.fold((_) => null, (value) => value),
            openQuestions: questions.fold(
              (_) => const <ReturnedGoodsQuestion>[],
              (value) => value,
            ),
            capitalRequests: requests.fold(
              (_) => const <CapitalRequest>[],
              (value) => value,
            ),
            expenses: expenses.fold(
              (_) => const <PoolExpense>[],
              (value) => value,
            ),
          ),
        );
      },
    );
  }

  /// «صالحة» أو «تالفة» — and the close it was holding up becomes possible.
  ///
  /// Reloads the whole screen afterwards rather than removing the row: «تالفة» posts a stock
  /// adjustment, so the pool's stock at cost and its deployable cash both moved.
  Future<Failure?> answerReturnedGoods({
    required int poolId,
    required int questionId,
    required String verdict,
    required int warehouseId,
    String? notes,
  }) async {
    final result = await _answerReturnedGoods(
      questionId: questionId,
      verdict: verdict,
      warehouseId: warehouseId,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(poolId);

      return null;
    });
  }

  /// Offers capital or asks for it back.
  ///
  /// The screen must show what `capital_timing` says **before** this is called — outside the
  /// grace window the money does not move today, and a person who was not told that will think
  /// the form failed.
  Future<Failure?> requestCapital({
    required int poolId,
    required int investorId,
    required String direction,
    required String amount,
    String? notes,
  }) async {
    final result = await _requestCapital(
      poolId: poolId,
      investorId: investorId,
      direction: direction,
      amount: amount,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(poolId);

      return null;
    });
  }

  /// Only before it has taken effect. Unwinds nothing — the money never left his wallet.
  Future<Failure?> cancelCapitalRequest({
    required int poolId,
    required int requestId,
  }) async {
    final result = await _cancelCapitalRequest(requestId);

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(poolId);

      return null;
    });
  }
}

@freezed
sealed class PoolDetailState with _$PoolDetailState {
  const factory PoolDetailState.loading() = PoolDetailLoading;

  const factory PoolDetailState.loaded({
    required InvestmentPool pool,

    /// Null when the figure could not be read — the screen shows the pool without it rather
    /// than showing nothing.
    PoolDeployableCash? cash,

    /// **Open ones only.** These are the work, and they are what the close is waiting for.
    @Default(<ReturnedGoodsQuestion>[])
    List<ReturnedGoodsQuestion> openQuestions,

    @Default(<CapitalRequest>[]) List<CapitalRequest> capitalRequests,

    /// What has been charged to the pool, newest first.
    @Default(<PoolExpense>[]) List<PoolExpense> expenses,
  }) = PoolDetailLoaded;

  const factory PoolDetailState.failure(Failure failure) = PoolDetailFailure;
}
