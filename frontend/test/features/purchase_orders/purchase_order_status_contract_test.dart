import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';

/// The mechanical guard on the app's copy of the purchase-order state machine.
///
/// **This app holds a copy of `allowedNext()`, and it is the only place it does.** An *order*
/// arrives with `available_transitions` already narrowed to what the signed-in user may do, so
/// its screen holds no rules at all. `PurchaseOrderResource` publishes only `status` — so the
/// buttons on a purchase order are drawn from a map typed out here by hand, in a different
/// language, with no compiler watching either side.
///
/// So this test reads the PHP. Both repositories live in one workspace, which makes it free —
/// and when the backend is not checked out it **skips** rather than fails, so a frontend-only
/// checkout still goes green. The same arrangement as `order_status_contract_test.dart`.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File(
    '../backend/app/Domain/PurchaseOrder/Enums/PurchaseOrderStatus.php',
  );

  /// `case New = 'new';` — every status the backend defines, keyed by its PHP case name.
  Map<String, String> wireOf(String php) => {
    for (final match in RegExp("case (\\w+) = '([^']+)';").allMatches(php))
      match.group(1)!: match.group(2)!,
  };

  /// The Arabic each one is given, read out of `label()` alone — a regex over the whole file
  /// would read an `allowedNext()` arm as a label.
  Map<String, String> labels(String php) {
    final method = php.substring(
      php.indexOf('public function label(): string'),
      php.indexOf('public function allowedNext'),
    );

    return {
      for (final match in RegExp("self::(\\w+) => '([^']+)',").allMatches(method))
        match.group(1)!: match.group(2)!,
    };
  }

  /// `self::New => [self::Arrived, self::Cancelled],` — the map itself, by case name.
  Map<String, List<String>> transitions(String php) {
    final start = php.indexOf('public function allowedNext');
    final method = php.substring(start, php.indexOf('public function', start + 10));

    final map = <String, List<String>>{};

    for (final match in RegExp(r'self::(\w+) => \[([^\]]*)\],').allMatches(method)) {
      final targets = RegExp(r'self::(\w+)')
          .allMatches(match.group(2)!)
          .map((m) => m.group(1)!)
          .toList();

      map[match.group(1)!] = targets;
    }

    // `self::Completed, self::Cancelled => [],` — the terminal pair, written as one arm.
    for (final match
        in RegExp(r'self::(\w+), self::(\w+) => \[\],').allMatches(method)) {
      map[match.group(1)!] = const [];
      map[match.group(2)!] = const [];
    }

    return map;
  }

  bool skipWithoutBackend() {
    if (source.existsSync()) return false;

    markTestSkipped('backend not checked out beside this one — nothing to compare against');

    return true;
  }

  test('every status the backend defines has a case in this app', () {
    // Arrange
    if (skipWithoutBackend()) return;

    // Act
    final backend = wireOf(source.readAsStringSync()).values.toSet();
    // `unknown` is this app's own: it is what a status this build has never heard of parses as.
    final app = PurchaseOrderStatus.choices.map((status) => status.wire).toSet();

    // Assert — named in each direction, because the two failures need different fixes.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing — did the PHP change shape?');
    expect(app.difference(backend), isEmpty, reason: 'this app knows statuses the backend does not');
    expect(backend.difference(app), isEmpty, reason: 'the backend defines statuses this app has no case for');
  });

  test('every status is called what the server calls it', () {
    // Arrange
    if (skipWithoutBackend()) return;

    final php = source.readAsStringSync();
    final wire = wireOf(php);
    final label = labels(php);

    // Act
    final serverWords = {
      for (final entry in label.entries) ?wire[entry.key]: entry.value,
    };

    // Assert — the filter chips name a status before any order is loaded, so the word cannot
    // come down the wire and has to be right here.
    for (final status in PurchaseOrderStatus.choices) {
      expect(
        status.label,
        serverWords[status.wire],
        reason: '«${status.label}» is not what the server calls ${status.wire}',
      );
    }
  });

  test('the moves this app offers are exactly the moves the server allows', () {
    // Arrange — the load-bearing one. A button drawn from a stale copy of this map is a request
    // the server answers with «لا يمكن نقل أمر الشراء…», on a screen that offered it.
    if (skipWithoutBackend()) return;

    final php = source.readAsStringSync();
    final wire = wireOf(php);
    final map = transitions(php);

    expect(map, isNotEmpty, reason: 'the regex matched nothing — did allowedNext() change shape?');

    // Act & Assert
    for (final entry in map.entries) {
      final from = PurchaseOrderStatus.fromWire(wire[entry.key]);
      final expected = entry.value.map((name) => wire[name]).toSet();
      final offered = from.allowedNext.map((status) => status.wire).toSet();

      expect(
        offered,
        expected,
        reason: 'the app offers the wrong moves out of «${from.label}»',
      );
    }
  });

  test('cancelling is the only move a person chooses', () {
    // Arrange & Act — the map and the buttons are two different questions, and the app has to
    // hold them apart: `allowedNext` mirrors the enum, `offeredNext` is what is drawn.
    final onTheMap = {
      for (final status in PurchaseOrderStatus.values) ...status.allowedNext,
    };
    final onButtons = {
      for (final status in PurchaseOrderStatus.values) ...status.offeredNext,
    };

    // Assert — two statuses are on the map and on no button, for different reasons.
    //
    // «مكتمل»: the endpoint refuses it outright. Completion is earned by receiving the last of
    // the goods, never chosen — a button for it would earn «لا يمكن تحويل أمر الشراء إلى هذه
    // الحالة يدوياً».
    //
    // «قيد الاستلام»: the endpoint accepts it, and nothing needs it. A shipment may be booked in
    // straight from «جديد», and posting one moves the order there by itself — so the only thing
    // a manual button achieved was locking the paperwork before anything had turned up.
    expect(onTheMap, containsAll(<PurchaseOrderStatus>[
      PurchaseOrderStatus.completed,
      PurchaseOrderStatus.arrived,
    ]));
    expect(onButtons, {PurchaseOrderStatus.cancelled});
  });
}
