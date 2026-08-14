import 'dart:io';

import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mechanical guard on one status having one name.
///
/// A single order always shows the server's own `status_label`, so it cannot drift. What *can*
/// drift is this app's two hand-copies of the same vocabulary: [OrderStatus]'s wire values, and
/// the Arabic the filter sheet prints beside each row. Both were typed here by hand, in a
/// different language, with no compiler watching either side — which is how «ملغاة» and «ملغاة
/// كلياً» ended up being the same status under two names in two places.
///
/// **Every status is checked, not just some.** The sheet used to offer *groups* — «قيد التنفيذ»
/// for two statuses, «رواجع» for four — and a group was allowed a name of its own, so only the
/// rows standing for exactly one status could be compared. Now that the filter names the real
/// statuses, every word on it has a counterpart over there and every one of them is pinned.
///
/// So this test reads the PHP enum. Both repositories live in one workspace, which makes it
/// free — and when the backend is not checked out it **skips** rather than fails, so a
/// frontend-only checkout still goes green. The same arrangement as
/// `permission_contract_test.dart`, for the same reason.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/app/Domain/Order/Enums/OrderStatus.php');

  /// `case New = 'new';` — every status the backend defines.
  Set<String> wires(String php) => RegExp("case \\w+ = '([^']+)';")
      .allMatches(php)
      .map((match) => match.group(1)!)
      .toSet();

  /// The Arabic each one is given, read out of `label()` alone.
  ///
  /// Scoped to that method on purpose: `permission()` and `timestampColumn()` are written in
  /// the same `self::Case => …` shape, and a regex over the whole file would read a permission
  /// name as a status label.
  Map<String, String> labels(String php) {
    final method = php.substring(
      php.indexOf('public function label(): string'),
      php.indexOf('public function allowedNext'),
    );

    final cases = <String, String>{};
    for (final match in RegExp("self::(\\w+) => '([^']+)',").allMatches(method)) {
      cases[match.group(1)!] = match.group(2)!;
    }

    return cases;
  }

  /// `case New = 'new'` — the case name, so a label read by case can be matched to a wire.
  Map<String, String> wireOf(String php) {
    final cases = <String, String>{};
    for (final match in RegExp("case (\\w+) = '([^']+)';").allMatches(php)) {
      cases[match.group(1)!] = match.group(2)!;
    }

    return cases;
  }

  test('every status the backend defines has a case in this app', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act
    final backend = wires(source.readAsStringSync());
    // `unknown` is this app's own: it is what an order carrying a status this build has never
    // heard of parses as, so it deliberately has no counterpart over there.
    final app = OrderStatus.values
        .where((status) => status != OrderStatus.unknown)
        .map((status) => status.wire)
        .toSet();

    // Assert — named in each direction, because the two failures need different fixes: one is
    // a case to add here, the other is a case to delete.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing — did the PHP file change shape?');
    expect(
      app.difference(backend),
      isEmpty,
      reason: 'this app knows statuses the backend does not define',
    );
    expect(
      backend.difference(app),
      isEmpty,
      reason: 'the backend defines statuses this app has no OrderStatus case for',
    );
  });

  test('every status the filter offers uses the server own word for it', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    final php = source.readAsStringSync();
    final wire = wireOf(php);
    final label = labels(php);

    // Wire → the Arabic the server prints for it.
    final serverWords = {
      for (final entry in label.entries) ?wire[entry.key]: entry.value,
    };

    // Act
    final offered = OrderStatus.filterable;

    // Assert — one status, one word, whether it is read in the filter or on the order itself.
    expect(offered, isNotEmpty);
    for (final status in offered) {
      expect(
        status.label,
        serverWords[status.wire],
        reason: 'the filter calls «${status.wire}» something the server does not',
      );
    }
  });

  test('the filter offers every real status and nothing else', () {
    // Act
    final offered = OrderStatus.filterable;

    // Assert — a status missing from the sheet is a queue nobody can reach, and «unknown» is
    // this app's own invention: sending it as a filter would ask the server for a status it has
    // never defined.
    expect(offered, isNot(contains(OrderStatus.unknown)));
    expect(
      offered.toSet(),
      OrderStatus.values.toSet().difference({OrderStatus.unknown}),
    );
    // The machine's own order, so the sheet reads as the route an order takes.
    expect(offered, OrderStatus.values.where((s) => s != OrderStatus.unknown).toList());
  });
}
