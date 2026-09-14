import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortages_filter.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter/foundation.dart';

/// The النواقص list, its chip row, and the filters both of them are narrowed by.
///
/// **Every filter rides on every page**, including the ones `loadMore` asks for — a screen that
/// sent them separately would show the list narrowed by whichever landed last.
///
/// **The chip row is a second request, and it is asked without the status.** The board answers
/// «what *else* is there?», so narrowing it by the status already on screen would make every chip
/// but one read zero. Every other filter is kept, so «جديد ١٢» under a product filter means
/// twelve of that product.
///
/// **A shortage can change without this screen touching it.** A colleague can close the same one
/// from the order screen, and that sync runs on a queued listener — so it is not instant. Nothing
/// here re-fetches after an order write; the user pulls to refresh, and [PagedCubit.refresh]
/// re-runs the current question.
class ShortagesCubit extends PagedCubit<Shortage> {
  ShortagesCubit({required GetShortages getShortages, required GetShortageCounts getCounts})
    : _getShortages = getShortages,
      _getCounts = getCounts;

  final GetShortages _getShortages;
  final GetShortageCounts _getCounts;

  /// Which status the list is showing. Null is every status — **completed ones included**, which
  /// is what it opens on: the historical record is what the section is partly for.
  ShortageStatus? status;

  /// `'me'`, `'none'`, a user id as a string, or null for everybody's.
  String? assignedTo;

  int? productId;
  int? orderId;
  int? customerId;

  /// `manual` or `order`. Null is both.
  String? source;

  /// The chip row's numbers. Rebuilt on every question, and **never derived from the rows on
  /// screen** — a page of twenty says nothing about how many there are.
  final ValueNotifier<ShortageCounts> counts = ValueNotifier(const ShortageCounts.empty());

  @override
  Object identityOf(Shortage item) => item.id;

  @override
  Future<Either<Failure, Paginated<Shortage>>> fetchPage({String? search, required int page}) {
    // The board is refreshed beside the first page and never beside `loadMore`: the numbers
    // describe the whole question, and page two does not change it.
    if (page == 1) unawaited(_refreshCounts(search));

    return _getShortages(
      statuses: [?status],
      assignedTo: assignedTo,
      productId: productId,
      orderId: orderId,
      customerId: customerId,
      source: source,
      search: search,
      page: page,
    );
  }

  Future<void> _refreshCounts(String? search) async {
    final result = await _getCounts(
      assignedTo: assignedTo,
      productId: productId,
      orderId: orderId,
      customerId: customerId,
      source: source,
      search: search,
    );

    if (isClosed) return;

    // A failed board leaves the last numbers standing rather than blanking the row: the list
    // underneath it still answered, and zeros nobody measured would be a worse lie than stale
    // ones.
    result.fold((_) {}, (fresh) => counts.value = fresh);
  }

  /// Opens the list on a question somebody else settled — the shortages behind one order, say.
  ///
  /// **The filter's own fields are seeded, and the title is the caller's.** `ShortagesFilter`
  /// never crosses the wire; it travels as `extra` on one route, which is why an id in it has to
  /// be copied onto this cubit before the first page is asked for.
  Future<void> start(ShortagesFilter? filter) async {
    if (filter != null) {
      status = ShortageStatus.offered
          .where((candidate) => filter.statuses.contains(candidate.wire))
          .firstOrNull;
      assignedTo = filter.assignedTo;
      productId = filter.productId;
      orderId = filter.orderId;
      customerId = filter.customerId;
      source = filter.source;
    }

    await load();
  }

  /// Shows one status, or all of them.
  Future<void> showStatus(ShortageStatus? next) async {
    if (status == next) return;

    status = next;

    await load(search: currentSearch);
  }

  /// «المسندة إليّ» / «غير مُسنَدة» / everybody's — a filter, never a screen of its own.
  Future<void> showAssignedTo(String? next) async {
    if (assignedTo == next) return;

    assignedTo = next;

    await load(search: currentSearch);
  }

  /// «يدوي» / «من طلبية» / both — the one filter that sits on the page rather than in the sheet.
  Future<void> showSource(String? next) async {
    if (source == next) return;

    source = next;

    await load(search: currentSearch);
  }

  /// The filter sheet's answer, applied in one request rather than one per field.
  Future<void> applyFilters({
    required ShortageStatus? status,
    required String? assignedTo,
    required int? productId,
    required String? source,
  }) async {
    this.status = status;
    this.assignedTo = assignedTo;
    this.productId = productId;
    this.source = source;

    await load(search: currentSearch);
  }

  /// Whether a shortage still belongs under the status on screen — [PagedCubit.replace] drops it
  /// when a change took it out.
  @override
  bool belongs(Shortage item) => status == null || status == item.status;

  @override
  Future<void> close() {
    counts.dispose();

    return super.close();
  }
}

typedef ShortagesState = PagedState<Shortage>;
typedef ShortagesLoaded = PagedLoaded<Shortage>;
