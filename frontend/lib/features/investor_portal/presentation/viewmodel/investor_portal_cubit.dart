import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/usecases/get_investor_portfolio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor_portal_cubit.freezed.dart';
part 'investor_portal_state.dart';

/// The ViewModel behind the investor's own screen.
class InvestorPortalCubit extends Cubit<InvestorPortalState> {
  InvestorPortalCubit({required GetInvestorPortfolio getPortfolio})
    : _getPortfolio = getPortfolio,
      super(const InvestorPortalState.initial());

  final GetInvestorPortfolio _getPortfolio;

  Future<void> load() async {
    emit(const InvestorPortalState.loading());
    await _fetch();
  }

  /// Pull to refresh: whatever is on screen stays there while the request runs, and survives its
  /// failure. Throwing away figures somebody is reading because a refresh timed out is the worst
  /// of the available answers.
  Future<void> refresh() async {
    if (state case final InvestorPortalLoaded loaded) {
      final lastGood = loaded.copyWith(isRefreshing: false);

      emit(loaded.copyWith(isRefreshing: true));
      await _fetch(previous: lastGood);

      return;
    }

    await load();
  }

  Future<void> _fetch({InvestorPortalLoaded? previous}) async {
    final result = await _getPortfolio();

    // The screen may have been left while the request was in flight; emitting into a closed
    // Cubit throws.
    if (isClosed) return;

    // Closures rather than tear-offs: `const_finder` breaks a release build on a tear-off of a
    // Freezed union constructor.
    emit(
      result.fold(
        (failure) => previous ?? InvestorPortalState.failure(failure),
        (portfolio) => InvestorPortalState.loaded(portfolio: portfolio),
      ),
    );
  }
}
