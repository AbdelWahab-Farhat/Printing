import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// The mechanical guard on one status having one name.
///
/// A single order always shows the server's own `status_label`, so it cannot drift. What *can*
/// drift is this app's two hand-copies of the same vocabulary: [OrderStatus]'s wire values, and
/// the Arabic on the queue chips above the list. Both were typed here by hand, in a different
/// language, with no compiler watching either side — which is how «ملغاة» and «ملغاة كلياً»
/// ended up being the same status under two names in two places.
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

  test('a queue that names one status uses that status own word for it', () {
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

    // Act — only the chips that stand for exactly one status. «قيد التنفيذ», «عند العميل» and
    // «رواجع» name *groups*, and a group is allowed a name of its own: staff think in queues,
    // which is the whole reason those three exist.
    final single = OrderQueue.values.where((queue) => queue.statuses.length == 1);

    // Assert — one status, one word, whether it is read on a chip or on the order itself.
    for (final queue in single) {
      expect(
        queue.label,
        serverWords[queue.statuses.single.wire],
        reason: 'the «${queue.label}» chip calls one status something the server does not',
      );
    }
  });
}
