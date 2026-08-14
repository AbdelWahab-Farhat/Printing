import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/usecases/get_profit_and_loss.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_and_loss_cubit.freezed.dart';
part 'profit_and_loss_state.dart';

/// The ViewModel behind الأرباح والخسائر: which days are being asked about, and what came back.
///
/// **The two days live on the Cubit rather than in the state.** They are what the pickers show
/// before any answer exists and they must survive a refusal — a 422 that emptied the boxes would
/// leave the user with an error about a period they can no longer see. Nothing reads them
/// without a rebuild following, because every change to either end runs [load], which emits.
///
/// The report the server sends echoes its own [PnlPeriod] back, and that echo is what the
/// figures are labelled with: it is the *normalised* window, which is not always the window
/// somebody typed.
class ProfitAndLossCubit extends Cubit<ProfitAndLossState> {
  ProfitAndLossCubit({required GetProfitAndLoss getSummary})
    : this._(getSummary, DateTime.now());

  /// **One `DateTime.now()` for both ends of the default window.** Read twice — once for the
  /// first of the month, once for today — a screen opened as the clock crosses midnight could
  /// take its two halves from different days.
  ProfitAndLossCubit._(this._getSummary, DateTime today)
    : from = _day(DateTime(today.year, today.month)),
      to = _day(today),
      super(const ProfitAndLossState.initial());

  final GetProfitAndLoss _getSummary;

  /// This month so far — the period a shop asks about without being asked which period it wants.
  String from;
  String to;

  /// First load, and every change of period: there is nothing on screen worth keeping, because
  /// figures kept from the old window would sit under the new one's dates and read as its answer.
  Future<void> load() async {
    emit(const ProfitAndLossState.loading());
    await _fetch();
  }

  /// Pull to refresh. The period has not moved, so whatever is on screen stays there while the
  /// request runs, and survives its failure.
  Future<void> refresh() async {
    if (state case final ProfitAndLossLoaded loaded) {
      await _fetch(previous: loaded);

      return;
    }

    await load();
  }

  /// Moves one end of the window, or both. A null end is left where it was — the two pickers
  /// change one at a time.
  ///
  /// A `to` that falls before `from` is sent anyway: the server owns that rule and answers it in
  /// its own Arabic, under the field it belongs to. See [GetProfitAndLoss].
  Future<void> setRange({String? from, String? to}) async {
    final nextFrom = from ?? this.from;
    final nextTo = to ?? this.to;

    // Re-picking the day already showing is not a reason to ask again.
    if (nextFrom == this.from && nextTo == this.to) return;

    this.from = nextFrom;
    this.to = nextTo;

    await load();
  }

  Future<void> _fetch({ProfitAndLossLoaded? previous}) async {
    final result = await _getSummary(from: from, to: to);

    // The screen may have been left while the request was in flight; emitting into a closed
    // Cubit throws.
    if (isClosed) return;

    emit(
      result.fold(
        // A refresh that fails leaves the last good report up rather than replacing real figures
        // with an error page.
        (failure) => previous ?? ProfitAndLossState.failure(failure),
        ProfitAndLossState.loaded,
      ),
    );
  }
}

/// The plain day the API filters on, taken from the phone's own clock.
String _day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
