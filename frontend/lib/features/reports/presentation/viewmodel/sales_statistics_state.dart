part of 'sales_statistics_cubit.dart';

/// Everything the board can be, and nothing it cannot.
///
/// A union rather than one class with `isLoading`, `failure` and `statistics` all nullable: that
/// shape permits "loading, and also failed, and also has figures", which has no rendering — and
/// is exactly how a spinner ends up spinning on top of an error nobody can see.
///
/// [loaded] carries no `isRefreshing` flag: a refresh here cannot be started while one is
/// running, because the only way to start one is a pull on a list already showing its own
/// indicator.
@freezed
sealed class SalesStatisticsState with _$SalesStatisticsState {
  const factory SalesStatisticsState.initial() = SalesStatisticsInitial;

  /// First load, or a period that just moved. The skeleton takes the page.
  const factory SalesStatisticsState.loading() = SalesStatisticsLoading;

  const factory SalesStatisticsState.loaded(SalesStatistics statistics) = SalesStatisticsLoaded;

  const factory SalesStatisticsState.failure(Failure failure) = SalesStatisticsFailure;
}

extension SalesStatisticsStateX on SalesStatisticsState {
  /// The server's own complaint about the day in «من», hung under that picker.
  ///
  /// The 422 is keyed by field precisely so it can be shown where the mistake was made, and this
  /// screen has exactly two places a mistake can be made.
  String? get fromError => _fieldError('from');

  /// The one that actually happens: «تاريخ النهاية يجب أن يكون بعد تاريخ البداية».
  String? get toError => _fieldError('to');

  /// True when the failure has something left to say after the two pickers have said theirs — a
  /// 403, a dropped connection, a 500. Those need the page; a wrong date does not.
  bool get hasUnrenderedErrors => switch (this) {
    SalesStatisticsFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => key != 'from' && key != 'to'),
      // No field errors at all.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SalesStatisticsFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
