import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The same mechanical guard `vendor_resource_contract_test.dart` puts on shipments, pointed at
/// orders, shelves and supplier paperwork.
///
/// **This is the failure that has no symptom.** A key the server adds does not crash anything:
/// it arrives, `fromJson` never looks for it, and the screen shows a blank — or worse, shows a
/// number in the wrong unit because the unit was published and dropped. Every one of these keys
/// is typed twice, once in PHP and once as a `@JsonKey`, in two languages with no compiler
/// watching either side.
///
/// Reads the **generated** parsers rather than the annotations, because those are what run.
///
/// Both repositories live in one workspace, which makes this free — and when the backend is not
/// checked out it **skips** rather than fails, so a frontend-only checkout still goes green.
///
/// Arrange - Act - Assert throughout.
void main() {
  final resources = Directory('../backend/app/Application/Api/V1/Resources');

  /// `'warehouse_quantity' => …` — every key a resource publishes, nested summaries included.
  Set<String> publishedKeys(File php) => RegExp("'([a-z_]+)' =>")
      .allMatches(php.readAsStringSync())
      .map((match) => match.group(1)!)
      .toSet();

  /// `json['warehouse_quantity']` — every key the generated `fromJson` reads.
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

  /// Each resource against the parsers that between them read its payload.
  ///
  /// More than one file per resource on purpose: an order embeds its customer, its lines and its
  /// transitions, and each of those is parsed by the model that owns it rather than copied into
  /// a second class that would have to be kept in step.
  const contracts = <String, List<String>>{
    'OrderResource': [
      'lib/features/orders/models/order.g.dart',
      'lib/features/orders/models/transition_field.g.dart',
      'lib/features/customers/models/customer.g.dart',
    ],
    'OrderItemResource': ['lib/features/orders/models/order.g.dart'],
    // One file, not two: the recorder it nests is declared beside the entry rather than reached
    // for from another feature, so the same generated parser reads `id` and `name` too.
    'ProductionCostEntryResource': ['lib/features/orders/models/production_cost_entry.g.dart'],
    'WarehouseStockResource': ['lib/features/warehouses/models/warehouse_stock.g.dart'],
    'PurchaseOrderResource': [
      'lib/features/purchase_orders/models/purchase_order.g.dart',
      'lib/features/vendors/models/stock_arrival.g.dart',
    ],
    'PurchaseOrderItemResource': [
      'lib/features/purchase_orders/models/purchase_order.g.dart',
      'lib/features/warehouses/models/warehouse_stock.g.dart',
    ],
  };

  /// Keys the server publishes that this app deliberately does not read.
  ///
  /// **An allowlist, not a silence.** Every entry is a decision with a reason, and anything not
  /// on it fails — which is the whole point: the list has to be edited on purpose, so a key that
  /// starts being dropped by accident cannot hide among the ones that are dropped on purpose.
  const ignored = <String, String>{
    // The app renders `*_label` — the server's own Arabic — and never the raw enum beside it.
    'fulfilment_type': 'the label is what is drawn; the wire value has no reader',
    'pricing_unit': 'lines show `pricing_unit_label`, the server\'s own word for it',
    'production_flow': 'the bar explains itself with `production_flow_label`; nothing branches '
        'on the road in this app, because the server sends the transitions already resolved',

    // Nested summaries the app reaches by other means.
    'shop': 'the order carries `customer_shop_id` and `customer_shop_name` flat, and uses those',

    // Ids whose *name* is what screens show. Kept out on purpose: an id on screen is a number
    // nobody can act on, and the snapshot beside it is the fact that survives a rename.
    'shipping_company_id': 'the carrier is shown by the snapshotted `shipping_company` name',

    // The per-status stamps. The timeline is built from `transitions`, which carries who and
    // when for every move — these columns would be a second, thinner copy of the same history.
    'ready_to_print_at': 'the timeline reads `transitions`, not the per-status columns',
    'design_started_at': 'the timeline reads `transitions`, not the per-status columns',
    'printing_started_at': 'the timeline reads `transitions`, not the per-status columns',
    'ready_at': 'the timeline reads `transitions`, not the per-status columns',
    'dispatched_at': 'the timeline reads `transitions`, not the per-status columns',
    'returned_at': 'the timeline reads `transitions`, not the per-status columns',
    'cancelled_at': 'the timeline reads `transitions`, not the per-status columns',

    'sort_order': 'the server sends the lines already in order; the app renders them as sent',
  };

  for (final MapEntry(key: name, value: generated) in contracts.entries) {
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
      final dropped = published.difference(parsed).difference(ignored.keys.toSet());

      // Assert
      expect(
        published,
        isNotEmpty,
        reason: 'the regex matched nothing — did the PHP change shape?',
      );
      expect(
        dropped,
        isEmpty,
        reason:
            'the server publishes these and the app drops them on the floor. Parse them, or '
            'add each to `ignored` with the reason it is deliberate',
      );
    });
  }

  test('nothing sits on the ignore list that the app already parses', () {
    // Arrange — an entry that stops being true is worse than no entry: it claims a decision was
    // made about a key somebody has since wired up, and it hides the next real drift behind it.
    if (!resources.existsSync()) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    final everyParser = contracts.values.expand((paths) => paths).toSet().toList();

    // Act
    final parsed = parsedKeys(everyParser);

    // Assert
    expect(
      ignored.keys.toSet().intersection(parsed),
      isEmpty,
      reason: 'these are on the ignore list but the app reads them — drop them from the list',
    );
  });
}
