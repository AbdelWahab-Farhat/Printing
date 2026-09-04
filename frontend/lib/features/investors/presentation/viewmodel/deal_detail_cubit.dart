import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'deal_detail_cubit.freezed.dart';

/// One deal: its terms, its goods, and what each investor stands at.
class DealDetailCubit extends Cubit<DealDetailState> {
  DealDetailCubit({
    required GetInvestorDeal getDeal,
    required ChangeDealState changeState,
    required RecordDealExpense recordExpense,
  }) : _getDeal = getDeal,
       _changeState = changeState,
       _recordExpense = recordExpense,
       super(const DealDetailState.loading());

  final GetInvestorDeal _getDeal;
  final ChangeDealState _changeState;
  final RecordDealExpense _recordExpense;

  Future<void> load(int id) async {
    final result = await _getDeal(id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DealDetailState.failure(failure),
        (deal) => DealDetailState.loaded(deal: deal),
      ),
    );
  }

  /// Opens the deal — which also closes its terms, because they are what the money is split by.
  Future<Failure?> open(int id) => _act(id, () => _changeState.open(id));

  /// Closes it, settling every investor and returning his money to his wallet.
  ///
  /// The server refuses while stock is left or while an order that took this deal's goods has
  /// not reached the customer, and its refusal is what the screen shows — the app does not
  /// duplicate either rule.
  // Named `closeDeal`, not `close`: `Cubit.close()` already exists and shadowing it would make
  // «أغلق الصفقة» tear down the ViewModel instead.
  Future<Failure?> closeDeal(int id) => _act(id, () => _changeState.close(id));

  Future<Failure?> addExpense({
    required int dealId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) async {
    final result = await _recordExpense(
      dealId: dealId,
      kind: kind,
      name: name,
      amount: amount,
      incurredOn: incurredOn,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(dealId);

      return null;
    });
  }

  Future<Failure?> _act(int id, Future<Either<Failure, InvestorDeal>> Function() run) async {
    final result = await run();

    if (isClosed) return null;

    return result.fold((failure) => failure, (deal) {
      emit(DealDetailState.loaded(deal: deal));

      return null;
    });
  }
}

@freezed
sealed class DealDetailState with _$DealDetailState {
  const factory DealDetailState.loading() = DealDetailLoading;

  const factory DealDetailState.loaded({required InvestorDeal deal}) = DealDetailLoaded;

  const factory DealDetailState.failure(Failure failure) = DealDetailFailure;
}
