import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_state.dart';

/// The ViewModel every searchable list in this app is, minus the one thing that differs.
///
/// Products, customers, cities and everything that follows them all needed the same five
/// behaviours, and each had been re-implementing them:
///
///   * **debounced search** — a five-letter word is one request, not five,
///   * **out-of-order protection** — a slow response for "أك" must not overwrite a later,
///     faster "أكياس"; a counter, not a timestamp, because two requests can share a millisecond,
///   * **`isClosed` before every emit** — the screen may be gone while a request is in flight,
///   * **append, never replace, on `loadMore`** — and *keep what is on screen* when that page
///     fails, because losing a working list to a failed page four is the worse answer,
///   * **`refresh` re-runs the current term**, not a blank one.
///
/// Every one of those is a bug somebody has shipped by forgetting it. Written once here, a new
/// list screen gets all five by declaring what to fetch:
///
/// ```dart
/// class ProductsCubit extends PagedCubit<Product> {
///   ProductsCubit({required GetProducts getProducts}) : _getProducts = getProducts;
///   final GetProducts _getProducts;
///
///   @override
///   Future<Either<Failure, Paginated<Product>>> fetchPage({String? search, required int page}) =>
///       _getProducts(search: search, page: page);
/// }
/// ```
///
/// **What is deliberately not here:** anything a particular list does *besides* paging — cities
/// loading the regions of a selection, for instance. Those stay in the feature's own Cubit,
/// which is free to extend this and add to it. This class owns the paging and nothing else.
abstract class PagedCubit<T> extends Cubit<PagedState<T>> {
  PagedCubit() : super(PagedState<T>.initial());

  /// Long enough that a word typed at speed is one request, short enough that the list does not
  /// feel stuck behind the typing.
  static const Duration debounceDelay = Duration(milliseconds: 350);

  Timer? _debounce;
  String? _search;

  /// Guards against an out-of-order response. Incremented for every request this Cubit starts;
  /// a reply whose id is no longer the current one is a reply to a question nobody is asking.
  int _requestId = 0;

  /// The term the list is currently showing, if any.
  String? get currentSearch => _search;

  /// The one thing a subclass has to provide: how to get a page.
  ///
  /// It calls a use case — never a repository and never Dio, which is the layering rule this
  /// class is not allowed to bend just because it lives in `core/`.
  Future<Either<Failure, Paginated<T>>> fetchPage({String? search, required int page});

  /// First load, or a load with a new term. Replaces whatever is on screen with a skeleton.
  Future<void> load({String? search}) async {
    _search = search;
    final requestId = ++_requestId;

    emit(PagedState<T>.loading());

    final result = await fetchPage(search: search, page: 1);

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        PagedState<T>.failure,
        (page) => PagedState<T>.loaded(page: page, search: search),
      ),
    );
  }

  /// Typing in the search box. Waits for a pause before touching the network.
  void search(String term) {
    _debounce?.cancel();
    _debounce = Timer(debounceDelay, () {
      final trimmed = term.trim();

      // An empty box means "everything", not "search for nothing" — sending `''` would filter
      // on an empty string and quietly return the wrong thing.
      unawaited(load(search: trimmed.isEmpty ? null : trimmed));
    });
  }

  /// Appends the next page. A no-op while one is already loading or once the last page has been
  /// reached — an infinite list fires its callback far more often than it needs to.
  Future<void> loadMore() async {
    final current = state;
    if (current is! PagedLoaded<T>) return;
    if (current.isLoadingMore || !current.page.hasMore) return;

    final requestId = ++_requestId;
    emit(current.copyWith(isLoadingMore: true));

    final result = await fetchPage(
      search: _search,
      page: current.page.meta.currentPage + 1,
    );

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        // The pages already loaded stay; only the footer clears.
        (failure) => current.copyWith(isLoadingMore: false),
        (next) => current.copyWith(page: current.page.merge(next), isLoadingMore: false),
      ),
    );
  }

  /// Pull to refresh — the same term, from page one.
  Future<void> refresh() => load(search: _search);

  @override
  Future<void> close() {
    _debounce?.cancel();

    return super.close();
  }
}
