import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the two tick boxes on the filter sheet mean to the API.
///
/// The sheet answers in booleans because that is what a tick box is; the request needs
/// `has_orders` and `sort`. This is the one place that translation happens, so it is the one
/// place it can be wrong.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('the untouched filter asks for nothing in particular', () {
    // Arrange
    const filter = CustomersFilter();

    // Act
    final asked = (filter.hasOrders, filter.sort, filter.isNarrowed);

    // Assert — null, not false: `has_orders=0` would be «only those who never ordered», and the
    // list a tab opens on is everybody.
    expect(asked, (null, CustomersSort.newest, false));
  });

  test('«بدون طلبات» asks for the customers who have never ordered', () {
    // Arrange
    const filter = CustomersFilter(hasOrders: false);

    // Act
    final asked = (filter.hasOrders, filter.isNarrowed);

    // Assert
    expect(asked, (false, true));
  });

  test('«لديهم طلبات» asks for the other half of the register', () {
    // Arrange — the third state, and the reason `hasOrders` is nullable rather than a bool: a
    // flag with a default could say «الكل» and «بدون طلبات» but never this.
    const filter = CustomersFilter(hasOrders: true);

    // Act
    final asked = (filter.hasOrders, filter.isNarrowed);

    // Assert
    expect(asked, (true, true));
  });

  test('«الأقدم طلباً» changes the order without narrowing the set', () {
    // Arrange
    const filter = CustomersFilter(leastRecentOrderFirst: true);

    // Act
    final asked = (filter.hasOrders, filter.sort, filter.isNarrowed);

    // Assert — every customer is still in the list; only the order changed. `isNarrowed` says
    // whether the button is drawn as active, and a sort is a change worth showing.
    expect(asked, (null, CustomersSort.leastRecentOrder, true));
  });

  test('both at once is a question the API is allowed to be asked', () {
    // Arrange — «العملاء الذين لم يطلبوا» sorted by when they last ordered is an empty sort
    // over an answered filter, and neither cancels the other.
    const filter = CustomersFilter(hasOrders: false, leastRecentOrderFirst: true);

    // Act
    final asked = (filter.hasOrders, filter.sort);

    // Assert
    expect(asked, (false, CustomersSort.leastRecentOrder));
  });

  test('the sort values are the words the API knows', () {
    // Arrange
    const sorts = CustomersSort.values;

    // Act
    final wire = sorts.map((sort) => sort.wire).toList();

    // Assert — spelled as `CustomerSort` spells them in the backend; this test is the copy of
    // that enum this app is allowed to keep.
    expect(wire, ['newest', 'least_recent_order']);
  });

  test('two filters holding the same answers are the same filter', () {
    // Arrange
    const filter = CustomersFilter(hasOrders: false);

    // Act
    final isSame = filter == const CustomersFilter(hasOrders: false);

    // Assert — the sheet hands back a new instance on every «تطبيق», and a screen that could
    // not tell it from the one it already had would refetch the list for a tap that changed
    // nothing.
    expect(isSame, isTrue);
  });

  test('the two halves of the orders question are not the same filter', () {
    // Arrange
    const withOrders = CustomersFilter(hasOrders: true);

    // Act
    final isSame = withOrders == const CustomersFilter(hasOrders: false);

    // Assert — they were one boolean apart before the third state existed, and equality is what
    // decides whether the list is refetched.
    expect(isSame, isFalse);
  });
}
