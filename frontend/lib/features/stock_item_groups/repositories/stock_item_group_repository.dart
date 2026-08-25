import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';

/// مجموعات الأصناف, stated without saying how.
///
/// **[group] is not a nicety on top of [groups].** The list endpoint has no way to ask for the
/// sizes of a material — `/stock-items` accepts no `stock_item_group_id`, by design — so
/// `GET /stock-item-groups/{id}` is the *only* place `items[]` exists. A screen that wants to
/// show what a material contains has to read one, and no amount of filtering the list will do
/// it.
abstract interface class StockItemGroupRepository {
  /// One page of the materials.
  ///
  /// [isActive] left null returns the stopped ones too, which is what a screen for *curating*
  /// the table has to do — a material somebody stopped last month is exactly the one they come
  /// back looking for. A picker passes `true`: offering a stopped material would file a new
  /// size under something the shop no longer buys.
  Future<Either<Failure, Paginated<StockItemGroup>>> groups({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  /// One material **with its sizes**, smallest first. The only response that carries `items[]`.
  Future<Either<Failure, StockItemGroup>> group(int groupId);

  /// [defaultUnit] is required here and optional on [update]: a material must say what a size
  /// under it starts out counted in before the first one can be created.
  Future<Either<Failure, StockItemGroup>> create({
    required String name,
    required StockUnit defaultUnit,
    String? description,
    bool isActive = true,
  });

  /// **Saving a new [name] renames every size filed under this material**, in one transaction
  /// on the server. Ask before calling; see `StockItemGroup.renamesItems`.
  ///
  /// [defaultUnit] is nullable because omitting it keeps the current one — and because sending
  /// it changes nothing that exists: it decides what a size created *after* this save starts
  /// out counted in, and nothing else. No shelf moves.
  Future<Either<Failure, StockItemGroup>> update(
    int groupId, {
    required String name,
    StockUnit? defaultUnit,
    String? description,
    bool? isActive,
  });

  /// The server refuses one that any size or any product still points at, and says so in Arabic
  /// naming both counts. Answers with the server's own message.
  Future<Either<Failure, String>> delete(int groupId);
}
