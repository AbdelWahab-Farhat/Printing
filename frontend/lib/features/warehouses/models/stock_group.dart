import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter/foundation.dart';

/// Every shelf of one product, in the order the server sent them.
///
/// **Not a thing the API returns.** The endpoint answers one row per *size*, which is the right
/// answer — a balance belongs to a size, never to a product — but it is not the right *reading*:
/// a warehouse holding «أكياس الشحن» in four sizes showed the same name four times, and the eye
/// had to re-read every row to notice they were the same bag. The grouping is presentation and
/// stays here, where it can be tested without a widget.
///
/// **Nothing is summed.** A group carries its shelves and no total: the balances are counted in
/// whatever unit each shelf was stocked in, and a client that adds them up is doing arithmetic
/// this app has deliberately never done — see [WarehouseStock].
@immutable
class StockGroup {
  const StockGroup(this.shelves);

  /// One or more, never empty, and in the server's order.
  final List<WarehouseStock> shelves;

  /// Groups shelves by the product they are sizes of, keeping first-appearance order.
  ///
  /// The server orders by size id, so two sizes of one bag can arrive with another product's
  /// between them; they are still one bag, so grouping is by key rather than by adjacency.
  static List<StockGroup> from(Iterable<WarehouseStock> stocks) {
    final byProduct = <Object, List<WarehouseStock>>{};

    for (final stock in stocks) {
      // A line that arrived without its product is nobody's size but its own: keyed by the
      // shelf itself, it stands alone rather than joining a group nothing shows it belongs to.
      final key = stock.variant?.productId ?? 'shelf-${stock.id}';

      byProduct.putIfAbsent(key, () => <WarehouseStock>[]).add(stock);
    }

    return [for (final shelves in byProduct.values) StockGroup(shelves)];
  }

  WarehouseStock get first => shelves.first;

  /// One size, which is drawn as a plain row: a header naming a product above a single line
  /// repeating it is a card that says everything twice.
  bool get isSingle => shelves.length == 1;

  String get productName => first.variant?.productName ?? first.title;

  String? get productCode => first.variant?.productCode;

  /// The product's own photograph — there are none at size level, so any size that has one has
  /// the group's. Taken from the first that carries it rather than from the first shelf, which
  /// may be a size minted before the server started sending it.
  String? get imageUrl => _illustrated?.imageUrl;

  /// [imageUrl] as the catalogue's own thumbnail takes it, or null for a product nobody has
  /// photographed.
  ProductImage? get image => switch (_illustrated) {
    final variant? => ProductImage(id: variant.id, url: variant.imageUrl!),
    _ => null,
  };

  StockVariant? get _illustrated {
    for (final shelf in shelves) {
      if (shelf.variant?.imageUrl != null) return shelf.variant;
    }

    return null;
  }

  /// Stable across a refresh that returns the same shelves — what a list needs to keep a card's
  /// state where it is rather than rebuild it as a new one.
  Object get key => first.variant?.productId ?? 'shelf-${first.id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StockGroup && listEquals(other.shelves, shelves));

  @override
  int get hashCode => Object.hashAll(shelves);
}
