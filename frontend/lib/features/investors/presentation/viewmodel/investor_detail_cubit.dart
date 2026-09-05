import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor_detail_cubit.freezed.dart';

/// One investor, his balances, and the money moves recorded against him.
class InvestorDetailCubit extends Cubit<InvestorDetailState> {
  InvestorDetailCubit({
    required GetInvestor getInvestor,
    required RecordWalletEntry recordWalletEntry,
  }) : _getInvestor = getInvestor,
       _recordWalletEntry = recordWalletEntry,
       super(const InvestorDetailState.loading());

  final GetInvestor _getInvestor;
  final RecordWalletEntry _recordWalletEntry;

  Future<void> load(int id) async {
    final result = await _getInvestor(id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => InvestorDetailState.failure(failure),
        (investor) => InvestorDetailState.loaded(investor: investor),
      ),
    );
  }

  /// Records a movement and re-reads the balances.
  ///
  /// Re-read rather than patched: the four figures are a walk of a ledger the server owns, and
  /// a client that recomputed them would be a second implementation of the rules — the one that
  /// disagrees the day a rule changes.
  ///
  /// Returns the failure to show, or null when it worked.
  Future<Failure?> record({
    required int investorId,
    required String type,
    required String amount,
    int? investorDealId,
    String? method,
    String? notes,
  }) async {
    final result = await _recordWalletEntry(
      investorId: investorId,
      type: type,
      amount: amount,
      investorDealId: investorDealId,
      method: method,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      load(investorId);

      return null;
    });
  }
}

@freezed
sealed class InvestorDetailState with _$InvestorDetailState {
  const factory InvestorDetailState.loading() = InvestorDetailLoading;

  const factory InvestorDetailState.loaded({required Investor investor}) = InvestorDetailLoaded;

  const factory InvestorDetailState.failure(Failure failure) = InvestorDetailFailure;
}
