import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every size of one material belongs on one card.
///
/// The list is one row per *shelf*, which is the truth — a balance belongs to a size and never to
/// a material — and a warehouse that stocks «كيس شحن» in four sizes read as four unrelated things
/// with the same name repeated four times. Grouping is the only thing here: the shelves
/// themselves are untouched, and their order is the server's.
///
/// **This used to group by product, and that was the bug the whole migration exists to fix.**
/// «كيس شحن سادة 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows and one pile of bags, so
/// heading a card with either product's name — or its photograph — picked one of the two
/// arbitrarily and told the storekeeper the shelf belonged to it. What a balance line now carries
/// about its identity is the material, the size and the code; there is no product and no picture
/// on it to group by, deliberately.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// One balance line. [material] `null` is a line that arrived without its nested item — the
  /// only case where the row says nothing about what it is a size of.
  WarehouseStock shelf({required int id, String? material, int? width, int? height}) =>
      WarehouseStock(
        id: id,
        warehouseId: 1,
        stockItemId: id,
        quantity: '10.000',
        unit: 'kg',
        unitLabel: 'كيلوغرام',
        item: material == null
            ? null
            : StockItemRef(
                id: id,
                code: 'S$id',
                name: material,
                widthCm: width,
                heightCm: height,
                // Composed server-side. Spelled out here rather than built from the parts for
                // exactly the reason the app never builds it either: a second implementation
                // would drift from the one the shortfall messages quote.
                displayName: width == null ? material : '$material $width*$height',
              ),
      );

  test('sizes of one material become one group', () {
    // Arrange
    final shelves = [
      shelf(id: 1, material: 'كيس شحن', width: 25, height: 35),
      shelf(id: 2, material: 'كيس شحن', width: 45, height: 50),
      shelf(id: 3, material: 'كيس شحن', width: 50, height: 60),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert — one heading for the three, because the material is what they genuinely share.
    // Each size keeps its own `S7` all the same: a shelf is a material *at a size*, so the
    // code identifies one pile and there is no code the group could say once for all of them.
    // That is the difference from the product card this replaced, where one code belonged to
    // the heading and no line had one of its own.
    expect(groups, hasLength(1));
    expect(groups.single.shelves.map((s) => s.id), [1, 2, 3]);
    expect(groups.single.materialName, 'كيس شحن');
    expect(groups.single.shelves.map((s) => s.code), ['S1', 'S2', 'S3']);
    expect(groups.single.isSingle, isFalse);
  });

  test('different materials stay apart, in the order the server sent them', () {
    // Arrange
    final shelves = [
      shelf(id: 1, material: 'كيس شحن', width: 25, height: 35),
      shelf(id: 2, material: 'ورق لاصق', width: 25, height: 35),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert — two materials at one size are still two piles, and the name is what separates
    // them: `stock_item_groups.name` is uniquely indexed and the server renames every size of a
    // material in the same transaction, so two sizes of one thing always agree on it and two
    // materials never can. Grouping by the only field the row carries is the same grouping.
    expect(groups.map((g) => g.materialName), ['كيس شحن', 'ورق لاصق']);
    expect(groups.every((g) => g.isSingle), isTrue);
  });

  test('one material split by another is still one group', () {
    // Arrange — the server orders by id, so two sizes of one material can arrive apart
    final shelves = [
      shelf(id: 1, material: 'كيس شحن', width: 25, height: 35),
      shelf(id: 2, material: 'ورق لاصق', width: 25, height: 35),
      shelf(id: 3, material: 'كيس شحن', width: 50, height: 60),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert — merged where it first appeared, and nothing is dropped: grouping is by key, not
    // by adjacency, or a material would split into two cards because another one landed between
    // its sizes.
    expect(groups, hasLength(2));
    expect(groups.first.shelves.map((s) => s.id), [1, 3]);
    expect(groups.last.shelves.map((s) => s.id), [2]);
  });

  test('a shelf that arrived without its item stands alone, named after itself', () {
    // Arrange — two such lines say nothing about belonging together, so they are not joined
    final shelves = [shelf(id: 1), shelf(id: 2)];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert — keyed by the shelf rather than by a name it does not have. Joining them under a
    // shared blank would claim a material the payload never mentioned, and each still gets a
    // heading of its own — «صنف #1» says less than a name and a great deal more than nothing.
    expect(groups, hasLength(2));
    expect(groups.every((g) => g.isSingle), isTrue);
    expect(groups.map((g) => g.materialName), ['مقاس #1', 'مقاس #2']);
  });

  test('a card keeps its key when the list around it changes', () {
    // Arrange — the list keys its cards by this. A key that moved with the shelves would rebuild
    // every card on every refresh, and the reader would lose their place mid-scroll.
    final before = StockGroup.from([
      shelf(id: 1, material: 'كيس شحن', width: 25, height: 35),
      shelf(id: 3, material: 'كيس شحن', width: 50, height: 60),
    ]).single;

    // Act — a refresh: a new material sorts ahead of the bags, and the 25*35 was emptied out of
    // this warehouse, so the group has one fewer shelf and is no longer first.
    final after = StockGroup.from([
      shelf(id: 2, material: 'ورق لاصق', width: 25, height: 35),
      shelf(id: 3, material: 'كيس شحن', width: 50, height: 60),
    ]).last;

    // Assert — the key is the material's name, not the first shelf's id, and it is stable for
    // exactly as long as the material's name is. A balance line carries no group id to use
    // instead, and a rename that reshuffles this list is a rename that changed every heading in
    // it anyway.
    expect(after.key, before.key);
    expect(after.materialName, before.materialName);
  });
}
