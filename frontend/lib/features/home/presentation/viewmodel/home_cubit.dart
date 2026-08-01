import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/auth/usecases/get_current_user.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/home/usecases/get_home_summary.dart';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

/// The ViewModel behind the home screen: who is signed in, and what the numbers say.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required GetCurrentUser getCurrentUser, required GetHomeSummary getHomeSummary})
    : _getCurrentUser = getCurrentUser,
      _getHomeSummary = getHomeSummary,
      super(const HomeState.initial());

  final GetCurrentUser _getCurrentUser;
  final GetHomeSummary _getHomeSummary;

  /// First load. Shows a skeleton, because there is nothing on screen to keep.
  Future<void> load() async {
    emit(const HomeState.loading());
    await _fetch();
  }

  /// Pull to refresh. Whatever is on screen stays there while the request runs, and survives
  /// its failure — throwing away a working screen because a refresh timed out is the worst of
  /// the available answers.
  Future<void> refresh() async {
    if (state case final HomeLoaded loaded) {
      // Captured *before* the refreshing flag goes up: passing the current state instead would
      // hand `_fetch` the spinner state as its fallback, and a failed refresh would leave the
      // screen refreshing forever.
      final lastGood = loaded.copyWith(isRefreshing: false);

      emit(loaded.copyWith(isRefreshing: true));
      await _fetch(previous: lastGood);

      return;
    }

    await load();
  }

  Future<void> _fetch({HomeLoaded? previous}) async {
    // Started together rather than awaited in turn: the identity and the numbers do not depend
    // on each other, so the screen waits for the slower one instead of for their sum.
    final pendingUser = _getCurrentUser();
    final pendingSummary = _getHomeSummary();

    final userResult = await pendingUser;
    final summaryResult = await pendingSummary;

    // The screen may have been left while the two were in flight; emitting into a closed Cubit
    // throws.
    if (isClosed) return;

    // Either both halves arrived or the screen has a failure to report: a card that cannot name
    // who is signed in, or numbers with nobody's name on them, is not worth drawing.
    final result = userResult.bind<HomeState>(
      (user) => summaryResult.map((summary) => HomeState.loaded(user: user, summary: summary)),
    );

    emit(
      result.fold(
        // A refresh that fails leaves the last good screen up rather than replacing real
        // numbers with an error page.
        (failure) => previous ?? HomeState.failure(failure),
        (loaded) => loaded,
      ),
    );
  }
}
