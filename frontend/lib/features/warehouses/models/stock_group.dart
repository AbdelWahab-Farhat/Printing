import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter/foundation.dart';

/// Every shelf of one material, in the order the server sent them.
///
/// **Not a thing the API returns.** The endpoint answers one row per *stock item*, which is the
/// right answer — a balance belongs to a size, never to a material — but it is not the right
/// *reading*: a warehouse holding «كيس شحن» in four sizes showed the same name four times, and
/// the eye had to re-read every row to notice they were the same bag. The grouping is
/// presentation and stays here, where it can be tested without a widget.
///
/// **Grouped by the material's name, which is the only thing the row carries about it.** The
/// nested `stock_item` on a balance line has no `stock_item_group_id`, and it does not need one:
/// the server renames every size of a material in the same transaction the material is renamed
/// in, precisely so `(name, size)` keeps identifying one shelf. Two sizes of one material
/// therefore always agree on [materialName], and two materials never can — the name is uniquely
/// indexed. Grouping by it is the same grouping, read off the field that is actually sent.
///
/// **This used to group by product, and that was the bug the whole change exists to fix.** Two
/// products at one size share one pile; heading a card with either of their names would have
/// picked one arbitrarily and told the storekeeper the wrong thing.
///
/// **Nothing is summed.** A group carries its shelves and no total: the balances are counted in
/// whatever unit each shelf was stocked in, and a client that adds them up is doing arithmetic
/// this app has deliberately never done — see [WarehouseStock].
@immutable
class StockGroup {
  const StockGroup(this.shelves);

  /// One or more, never empty, and in the server's order.
  final List<WarehouseStock> shelves;

  /// Groups shelves by the material they are sizes of, keeping first-appearance order.
  ///
  /// The server orders by id, so two sizes of one material can arrive with another material's
  /// between them; they are still one material, so grouping is by key rather than by adjacency.
  static List<StockGroup> from(Iterable<WarehouseStock> stocks) {
    final byMaterial = <Object, List<WarehouseStock>>{};

    for (final stock in stocks) {
      // A line that arrived without its item is nobody's size but its own: keyed by the shelf
      // itself, it stands alone rather than joining a group nothing shows it belongs to.
      final key = stock.item?.name ?? 'shelf-${stock.id}';

      byMaterial.putIfAbsent(key, () => <WarehouseStock>[]).add(stock);
    }

    return [for (final shelves in byMaterial.values) StockGroup(shelves)];
  }

  WarehouseStock get first => shelves.first;

  /// One size, which is drawn as a plain row: a header naming a material above a single line
  /// repeating it is a card that says everything twice.
  bool get isSingle => shelves.length == 1;

  /// «كيس شحن» — what these shelves have in common and the card's heading.
  String get materialName => first.materialName;

  /// Stable across a refresh that returns the same shelves — what a list needs to keep a card's
  /// state where it is rather than rebuild it as a new one.
  ///
  /// **The material's name, not an id**, because a balance line carries no group id. It is
  /// stable for exactly as long as the material's name is, which is the same span the card is
  /// on screen for — and a rename that reshuffles the list is a rename that changed every
  /// heading in it anyway.
  Object get key => first.item?.name ?? 'shelf-${first.id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StockGroup && listEquals(other.shelves, shelves));

  @override
  int get hashCode => Object.hashAll(shelves);
}
