import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        (next) => current.copyWith(page: _append(current.page, next), isLoadingMore: false),
      ),
    );
  }

  /// Appends the next page, minus anything the list is already showing.
  ///
  /// Offset paging asks for "rows 21 to 40", and the answer depends on where row 21 *is*. A row
  /// patched in locally — a customer registered a moment ago, sitting at the top — pushes the
  /// window down by one, so page two comes back starting with the row page one ended on. That is
  /// the price of offset paging and the server cannot pay it; refusing to show the same row
  /// twice is cheap here, and it is what makes [insert] safe to use on a list that scrolls.
  Paginated<T> _append(Paginated<T> page, Paginated<T> next) {
    final seen = page.items.map(identityOf).toSet();

    return page.merge(
      Paginated<T>(
        items: [
          for (final item in next.items)
            if (seen.add(identityOf(item))) item,
        ],
        meta: next.meta,
        extraMeta: next.extraMeta,
      ),
    );
  }

  /// Pull to refresh — the same term, from page one.
  Future<void> refresh() => load(search: _search);

  // ---------------------------------------------------------------------------------------
  // Patching: what a screen does with a change it already knows about.
  //
  // Coming back from a detail screen used to call `refresh()`, and refresh means `load()`:
  // a skeleton over the whole list, page one re-fetched, and a list scrolled halfway down
  // thrown back to the top. All of it to redraw a row whose new contents the caller was
  // *holding* — the detail screen had just been handed the saved model by the server.
  //
  // So the caller hands it over instead. A request goes out only when the app does not
  // already know the answer.
  // ---------------------------------------------------------------------------------------

  /// What makes two readings of the same row the same row — almost always its `id`.
  ///
  /// The one thing a generic list cannot work out for itself: `T` is a type variable here, and
  /// equality is not the question — an edited customer is *not* equal to the old one, and is
  /// still the same customer.
  @protected
  Object identityOf(T item);

  /// Whether [item] still belongs on this list as it is currently narrowed.
  ///
  /// The default keeps everything, which is right for a list whose only filter is its search
  /// term — the server owns that one, and a patched row is not re-matched against it. A screen
  /// with filters of its own overrides this so that a row edited *out* of the current question
  /// leaves the list: marking an order delivered while «جاهزة» is selected should take it off
  /// that list, and leaving it there makes the filter a lie until the next refresh.
  @protected
  bool belongs(T item) => true;

  /// Replaces one row with a newer reading of it, without a round trip.
  ///
  /// A no-op when the row is not on the pages currently loaded — it may be on page four, and
  /// inventing a position for it there would be a guess.
  ///
  /// Answers whether the list actually moved, which is what a screen carrying counts beside it
  /// needs: those are stale only when a row really changed.
  bool replace(T updated) {
    return _patch((items) {
      final id = identityOf(updated);
      final index = items.indexWhere((item) => identityOf(item) == id);
      if (index < 0) return null;

      if (!belongs(updated)) return [...items]..removeAt(index);

      return [...items]..[index] = updated;
    });
  }

  /// Puts a newly created row at the top, where the user just put it.
  ///
  /// **Only for a list the server itself returns newest-first** — customers, suppliers, orders,
  /// purchase orders, all `ORDER BY id DESC`. The top is exactly where the next read would put
  /// the row, so the screen and the server agree.
  ///
  /// The curated lists do not qualify and must not use this: products, categories, materials,
  /// business fields and warehouses are ordered by the business's own `sort_order` or by name,
  /// so where a new row belongs is the server's answer and not one this app can invent. Those
  /// screens re-read after a create — the one request in all of this that is still worth
  /// sending.
  bool insert(T created) {
    return _patch((items) {
      if (!belongs(created)) return null;
      if (items.any((item) => identityOf(item) == identityOf(created))) return null;

      return [created, ...items];
    });
  }

  /// Drops a row the caller knows is gone.
  ///
  /// Named for the id rather than `remove`, because several of these Cubits already own a
  /// `remove(model)` that calls the delete endpoint — this is the local half of that, and the
  /// two must not be mistakable for one another.
  bool removeById(Object id) {
    return _patch((items) {
      final index = items.indexWhere((item) => identityOf(item) == id);

      return index < 0 ? null : ([...items]..removeAt(index));
    });
  }

  /// The part all three share: only a loaded list can be patched, `total` follows the number of
  /// rows added or dropped, and everything else the endpoint sent in `meta` survives.
  ///
  /// [change] returns null for "nothing to do", which is what keeps a patch that matched
  /// nothing from emitting an identical state.
  bool _patch(List<T>? Function(List<T> items) change) {
    final current = state;
    if (current is! PagedLoaded<T>) return false;

    final items = change(current.page.items);
    if (items == null || isClosed) return false;

    final page = current.page;

    emit(
      current.copyWith(
        page: Paginated<T>(
          items: items,
          // The count under the list is the whole filtered set, not this page — so it moves by
          // however many rows the patch added or dropped, and never below zero.
          meta: page.meta.copyWith(
            total: (page.meta.total + items.length - page.items.length).clamp(0, 1 << 31),
          ),
          extraMeta: page.extraMeta,
        ),
      ),
    );

    return true;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();

    return super.close();
  }
}
