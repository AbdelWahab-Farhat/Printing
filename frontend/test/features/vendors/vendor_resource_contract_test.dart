import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The mechanical guard on every field the server publishes having somewhere to land.
///
/// `Vendor`, `StockArrival` and `StockArrivalItem` are twenty-five field names typed out twice —
/// once in a PHP resource and once as a `@JsonKey` over here — in two languages, with no
/// compiler watching either side. A key the server renames or adds does not fail: it simply
/// arrives and is dropped, and the screen shows a blank where the answer was.
///
/// So this reads the PHP resources and checks each key they publish is one the app's generated
/// `fromJson` actually looks for. It reads the **generated** files rather than the annotations,
/// because those are what run.
///
/// Both repositories live in one workspace, which makes this free — and when the backend is not
/// checked out it **skips** rather than fails, so a frontend-only checkout still goes green. The
/// same arrangement `permission_contract_test.dart` and `order_status_contract_test.dart` use.
///
/// Arrange - Act - Assert throughout.
void main() {
  final resources = Directory('../backend/app/Application/Api/V1/Resources');

  /// `'contact_person' => $this->contact_person,` — every key a resource publishes, including
  /// the ones inside a `whenLoaded` closure, since those are the nested summaries.
  Set<String> publishedKeys(File php) => RegExp("'([a-z_]+)' =>")
      .allMatches(php.readAsStringSync())
      .map((match) => match.group(1)!)
      .toSet();

  /// `json['contact_person']` — every key the generated `fromJson` reads.
  Set<String> parsedKeys(List<String> generated) {
    final keys = <String>{};

    for (final path in generated) {
      final source = File(path).readAsStringSync();
      keys.addAll(
        RegExp(r"json\['([a-z_]+)'\]").allMatches(source).map((match) => match.group(1)!),
      );
    }

    return keys;
  }

  /// The item's `product_variant` is parsed by `StockVariant`, which lives with the shelves —
  /// deliberately reused rather than copied, so its keys are read from there.
  const generated = [
    'lib/features/vendors/models/vendor.g.dart',
    'lib/features/vendors/models/stock_arrival.g.dart',
    'lib/features/warehouses/models/warehouse_stock.g.dart',
  ];

  for (final name in const ['VendorResource', 'StockArrivalResource', 'StockArrivalItemResource']) {
    test('every field $name publishes is one this app parses', () {
      // Arrange
      final php = File('${resources.path}/$name.php');

      if (!php.existsSync()) {
        markTestSkipped('backend not checked out beside this one — nothing to compare against');

        return;
      }

      // Act
      final published = publishedKeys(php);
      final parsed = parsedKeys(generated);

      // Assert
      expect(published, isNotEmpty, reason: 'the regex matched nothing — did the PHP change shape?');
      expect(
        published.difference(parsed),
        isEmpty,
        reason: 'the server publishes these and the app drops them on the floor',
      );
    });
  }

  test('a stock arrival is not given an updated_at to believe in', () {
    // Arrange
    final php = File('${resources.path}/StockArrivalResource.php');

    if (!php.existsSync()) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final published = publishedKeys(php);

    // Assert — an arrival is written once and never edited, so the server withholds the field
    // rather than publishing one that could never change. A model carrying `updatedAt` would be
    // inviting a screen to show a timestamp that is really the created one.
    //
    // Read from the *generated* parser, not the source: the model's own prose says the word
    // «updated_at» while explaining why it has none, and a grep over the comments would fail on
    // the explanation.
    expect(published, contains('created_at'));
    expect(published, isNot(contains('updated_at')));
    expect(
      parsedKeys(const ['lib/features/vendors/models/stock_arrival.g.dart']),
      isNot(contains('updated_at')),
    );
  });
}
