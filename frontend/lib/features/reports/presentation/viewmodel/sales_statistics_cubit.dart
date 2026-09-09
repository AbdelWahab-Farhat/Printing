import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:dayaa/features/reports/usecases/get_sales_statistics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_statistics_cubit.freezed.dart';
part 'sales_statistics_state.dart';

/// Which days إحصائيات المبيعات is being asked about, and what came back.
///
/// **The two days live on the Cubit rather than in the state**, exactly as they do on
/// [ProfitAndLossCubit] and for the same reason: they are what the pickers show before any answer
/// exists, and they must survive a refusal — a 422 that emptied the boxes would leave the user
/// with an error about a period they can no longer see. Nothing reads them without a rebuild
/// following, because every change to either end runs [load], which emits.
///
/// **[preset] lives here too, and it is the one thing this Cubit has that the P&L one does not.**
/// The API takes only `from`/`to`; «اليوم / هذا الأسبوع / هذا الشهر» are the client's arithmetic
/// over the phone's own clock, and the server never hears about them.
///
/// The board the server sends echoes its own [StatisticsPeriod] back, and **that echo is what the
/// figures are labelled with** — the normalised window, which is not always the one a preset
/// computed.
class SalesStatisticsCubit extends Cubit<SalesStatisticsState> {
  SalesStatisticsCubit({required GetSalesStatistics getStatistics})
    : this._(getStatistics, DateTime.now());

  /// **One `DateTime.now()` for the whole default window**, for the reason `ProfitAndLossCubit._`
  /// already documents: read twice — once for the first of the month, once for today — a screen
  /// opened as the clock crosses midnight could take its two halves from different days.
  SalesStatisticsCubit._(this._getStatistics, DateTime today)
    : from = _day(DateTime(today.year, today.month)),
      to = _day(today),
      super(const SalesStatisticsState.initial());

  final GetSalesStatistics _getStatistics;

  /// This month so far — the period a shop asks about without being asked which it wants, and
  /// the same default الأرباح والخسائر opens on, so the two screens agree on «الفترة» unread.
  String from;
  String to;

  /// Which chip is lit. Moved to [StatisticsPeriodPreset.custom] the moment a picker is used.
  ///
  /// **Changing it emits nothing, and no caller should expect it to.** A `Cubit` drops an `emit`
  /// whose state equals the one it already holds, so `emit(state)` after moving a field that
  /// lives *beside* the state is a call that silently does nothing — the chips would light a
  /// frame late, or never. Every change that alters the figures goes through [load] and emits on
  /// its own; the two that do not — revealing the pickers, and re-picking the day already
  /// showing — are repainted by the selector's own `setState`, which is where that piece of
  /// screen state belongs anyway.
  StatisticsPeriodPreset preset = StatisticsPeriodPreset.month;

  /// First load, and every change of period: there is nothing on screen worth keeping, because
  /// figures kept from the old window would sit under the new one's dates and read as its answer.
  Future<void> load() async {
    emit(const SalesStatisticsState.loading());
    await _fetch();
  }

  /// Pull to refresh. The period has not moved, so whatever is on screen stays there while the
  /// request runs, and survives its failure.
  Future<void> refresh() async {
    if (state case final SalesStatisticsLoaded loaded) {
      await _fetch(previous: loaded);

      return;
    }

    await load();
  }

  /// Switches to a named period and re-reads. Both ends are overwritten — a preset is an answer
  /// to «أي فترة؟», not an adjustment to the one showing.
  ///
  /// [StatisticsPeriodPreset.custom] is not a window and computes nothing: it is the state the
  /// pickers put the screen into, so asking for it here only reveals them.
  Future<void> selectPreset(StatisticsPeriodPreset next, {DateTime? now}) async {
    if (next == StatisticsPeriodPreset.custom) {
      preset = next;

      return;
    }

    // One reading of the clock for both ends, as above.
    final (nextFrom, nextTo) = next.window(now ?? DateTime.now());

    // Re-tapping the lit chip is not a reason to ask again.
    if (preset == next && nextFrom == from && nextTo == to) return;

    preset = next;
    from = nextFrom;
    to = nextTo;

    await load();
  }

  /// Moves one end of the window, or both. A null end is left where it was — the two pickers
  /// change one at a time.
  ///
  /// A `to` that falls before `from` is sent anyway: the server owns that rule and answers it in
  /// its own Arabic, under the field it belongs to. See [GetSalesStatistics].
  Future<void> setRange({String? from, String? to}) async {
    final nextFrom = from ?? this.from;
    final nextTo = to ?? this.to;

    // Re-picking the day already showing is not a reason to ask again — but it is still a
    // hand-picked window, so the chip moves even though no request goes out.
    if (nextFrom == this.from && nextTo == this.to) {
      preset = StatisticsPeriodPreset.custom;

      return;
    }

    preset = StatisticsPeriodPreset.custom;
    this.from = nextFrom;
    this.to = nextTo;

    await load();
  }

  Future<void> _fetch({SalesStatisticsLoaded? previous}) async {
    final result = await _getStatistics(from: from, to: to);

    // The screen may have been left while the request was in flight; emitting into a closed
    // Cubit throws.
    if (isClosed) return;

    emit(
      result.fold(
        // A refresh that fails leaves the last good board up rather than replacing real figures
        // with an error page.
        (failure) => previous ?? SalesStatisticsState.failure(failure),
        SalesStatisticsState.loaded,
      ),
    );
  }
}

/// The periods a person asks for by name, and the one they draw themselves.
///
/// **Named here rather than in the API**, deliberately: the app knows what day it is on the
/// phone in front of the reader, and the week it starts on is Saturday because the shop is in
/// Libya. Putting that calendar on the wire would version it forever in two places; a pair of
/// dates has no such problem.
enum StatisticsPeriodPreset {
  today('اليوم'),
  week('هذا الأسبوع'),
  month('هذا الشهر'),
  custom('فترة مخصصة');

  const StatisticsPeriodPreset(this.label);

  /// What the chip says.
  final String label;

  /// The two plain days this preset means, computed from one reading of the clock.
  ///
  /// **The week starts Saturday.** Dart's `weekday` runs Monday=1 … Sunday=7, so Saturday is 6
  /// and the offset back to the start of the week is `(weekday + 1) % 7` days — 0 on a Saturday,
  /// 1 on a Sunday, 6 on a Friday. A `DateTime` with a day-of-month at or below zero rolls back
  /// into the previous month on its own, so a week straddling a month boundary needs no case of
  /// its own.
  ///
  /// [StatisticsPeriodPreset.custom] is not a window; it answers with the day it was given at
  /// both ends rather than throwing, and no caller asks it.
  (String, String) window(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      StatisticsPeriodPreset.today => (_day(today), _day(today)),
      StatisticsPeriodPreset.week => (
        _day(today.subtract(Duration(days: (today.weekday + 1) % 7))),
        _day(today),
      ),
      StatisticsPeriodPreset.month => (_day(DateTime(today.year, today.month)), _day(today)),
      StatisticsPeriodPreset.custom => (_day(today), _day(today)),
    };
  }
}

/// The plain day the API filters on, taken from the phone's own clock.
String _day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
