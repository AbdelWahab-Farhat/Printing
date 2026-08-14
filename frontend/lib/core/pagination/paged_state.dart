import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paged_state.freezed.dart';

/// Everything a searchable, paginated list can be — for **any** `T`.
///
/// Every list screen in this app has the same four states and the same two flags, and had been
/// re-declaring them per feature: `CitiesState`, `ProductsState`, `CustomersState`, each with
/// its own copy of "loaded, plus a footer spinner, plus the term these results belong to". The
/// union is the same shape every time, so it is declared once here and specialised with a
/// `typedef` per feature — which keeps `ProductsLoaded` readable at call sites while there is
/// only one implementation to fix when something is wrong with it.
///
/// A generic Freezed union is fine precisely because **no state is ever serialised**: it is
/// `Paginated<T>` that crosses the wire, and that one is hand-assembled for exactly this reason.
@freezed
sealed class PagedState<T> with _$PagedState<T> {
  const factory PagedState.initial() = PagedInitial<T>;

  /// First load, or a new search term — the list is being replaced, so the screen shows a
  /// skeleton rather than stale rows under a spinner.
  const factory PagedState.loading() = PagedLoading<T>;

  const factory PagedState.loaded({
    required Paginated<T> page,

    /// A further page is on its way. Inside `loaded` rather than a case of its own, because
    /// everything already fetched stays on screen while it happens.
    @Default(false) bool isLoadingMore,

    /// The term these results belong to. Kept so an empty result can say *what* found nothing,
    /// and so a late response for an old term can be dropped instead of overwriting a newer one.
    String? search,
  }) = PagedLoaded<T>;

  const factory PagedState.failure(Failure failure) = PagedFailure<T>;
}
