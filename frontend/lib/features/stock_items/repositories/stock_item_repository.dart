import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';

/// «أصناف المخزون» — reading and curating the shelves, stated without saying how.
///
/// **Nothing here moves stock.** A balance changes only because a movement explains it, in the
/// same transaction — see `WarehouseRepository`. The one exception proves the rule and is spelt
/// out on [setUnit], which empties shelves *through the ledger* rather than behind it.
abstract interface class StockItemRepository {
  /// One page of the shelves, ordered `sort_order`, `name`, `width_cm`, `height_cm` — all
  /// ascending, so every size of one material reads together, smallest first.
  ///
  /// [search] matches the **name only**: not the code, and not the composed display name. So
  /// «كيس شحن» finds every size of the material and «S7» finds nothing — worth saying in the
  /// search box's hint rather than leaving somebody to conclude the shelf is gone.
  ///
  /// [widthCm] and [heightCm] filter independently and exactly. **A filter, not a constraint**:
  /// given a 25*35 variant a picker offers the 25*35 shelves first, but a 25*35 bag can
  /// legitimately be cut from a wider sheet, so dropping the size must stay one tap away.
  ///
  /// There is deliberately **no `stock_item_group_id` filter** — the API has none. The sizes of
  /// one material come from that material's own show endpoint, already smallest first.
  Future<Either<Failure, Paginated<StockItem>>> items({
    String? search,
    bool? isActive,
    int? widthCm,
    int? heightCm,
    int page = 1,
    int perPage = 20,
  });

  /// One shelf, carrying `variants_count`.
  Future<Either<Failure, StockItem>> item(int stockItemId);

  /// Opens a new shelf. It starts empty and in no warehouse — stock arrives through a movement.
  ///
  /// [stockItemGroupId] files it under a material, and **the material then decides two of these
  /// fields**: the name is the group's whatever is sent, and the unit falls back to its
  /// `default_unit`. That is why [name] is nullable here and required on [update] — without a
  /// material there is nothing to take it from.
  ///
  /// [unit] is settable **only here**. A pile has to be countable or weighable from the moment it
  /// exists, and moving it afterwards drags every balance and cost layer snapshotted against it —
  /// [setUnit]'s job, under locks.
  Future<Either<Failure, StockItem>> create({
    int? stockItemGroupId,
    String? name,
    int? widthCm,
    int? heightCm,
    required StockUnit unit,
    String? description,
    required bool isActive,
    required int sortOrder,
  });

  /// Corrects one. **A full replacement, and what gets left out is the trap**: the server fills
  /// every column from the body, so an absent `is_active` re-offers a shelf somebody stopped and
  /// an absent `sort_order` renumbers it to zero. Every field is therefore required or explicitly
  /// nullable here, and the form round-trips the two it has no control for.
  ///
  /// **Neither the unit nor the material can be changed by this call** — the server carries no
  /// rule for either, so sending them is silently ignored rather than refused. Re-filing a size
  /// under another material would rename it, and a rename is the one edit that can collide with a
  /// shelf that already exists.
  Future<Either<Failure, StockItem>> update(
    int stockItemId, {
    required String name,
    int? widthCm,
    int? heightCm,
    String? description,
    required bool isActive,
    required int sortOrder,
  });

  /// Declares what the pile is counted in — **and empties it**.
  ///
  /// ⚠️ **This does not convert the balance and does not relabel it. It discards it.** 200 bags
  /// are not 200 kilograms, so a quantity measured in one unit means nothing in another and the
  /// server ends it rather than restating it. Every warehouse holding the item is taken to zero
  /// by a recorded «تسوية نقص» *before* the unit changes — through the ledger, in the old unit,
  /// named to whoever asked — and only then is the item, its balances and its cost batches
  /// restamped.
  ///
  /// Re-picking the unit it already has does nothing at all, takes no locks and writes no
  /// movement. Nothing else in this app is allowed to call it without a confirmation that says
  /// the balance will be zeroed — see `showStockUnitSheet`.
  Future<Either<Failure, StockItem>> setUnit(int stockItemId, {required StockUnit unit});

  /// Removes a shelf. Soft, like every delete here: the balances that reached zero, the ledger
  /// explaining them and the item's own history all survive.
  ///
  /// **Refused twice, and both refusals are worth reading out.** While any warehouse still holds
  /// a quantity — «سوِّ الجرد أو انقل الكمية أولاً» — and again while any product size still draws
  /// on it — «غيّر ارتباط المقاسات أولاً». Answers with the server's own Arabic either way.
  Future<Either<Failure, String>> delete(int stockItemId);
}
