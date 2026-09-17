import 'dart:io';

import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mechanical guard on a badge having one name on both sides.
///
/// **The badge system is built to grow, and this is what keeps growing it honest.** Adding one
/// is meant to be a case in the PHP enum, an arm in `CountCustomerBadges`, a case here and a
/// place to draw it. The two enums are hand-copies of each other in different languages with no
/// compiler watching either side — exactly the arrangement that produced this app's worst
/// shipped bug, where `underReview` matched nothing and a notice never once appeared.
///
/// So the wires are read out of the PHP and pushed through this app's own lookup. When the
/// backend is not checked out beside this app the test **skips** rather than fails, the same
/// arrangement `design_rules_contract_test.dart` uses.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/app/Domain/Customer/Enums/CustomerBadge.php');

  /// `case Support = 'support';` — every badge the backend defines.
  Set<String> wires(String php) => RegExp(r"case \w+ = '([^']+)';")
      .allMatches(php)
      .map((match) => match.group(1)!)
      .toSet();

  test('every badge the server sends is one this build can name', () {
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this app');

      return;
    }

    // Arrange
    final php = source.readAsStringSync();
    final declared = wires(php);

    // Act
    final resolved = {for (final wire in declared) wire: CustomerBadge.fromWire(wire)};

    // Assert — a badge the app cannot name is one the server counts and nothing draws: the
    // number arrives and is silently dropped on the floor.
    expect(declared, isNotEmpty, reason: 'the regex found no cases — was the enum renamed?');

    resolved.forEach((wire, badge) {
      expect(badge, isNotNull, reason: "the server sends '$wire' and nothing here draws it");
    });
  });

  test('this build invents no badge the server does not have', () {
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this app');

      return;
    }

    // Arrange
    final declared = wires(source.readAsStringSync());

    // Act
    final ours = CustomerBadge.values.map((badge) => badge.wire).toSet();

    // Assert — the other direction, and it catches the likelier mistake: a badge added here in
    // anticipation, whose count never arrives because nobody wrote the server half. It would
    // draw nothing forever and look exactly like «لا يوجد جديد».
    expect(ours, declared);
  });

  test('an unknown key is ignored rather than fatal', () {
    // Arrange — a server that has grown a badge this build predates.

    // Act
    final unknown = CustomerBadge.fromWire('notifications');

    // Assert — null, so the repository can skip it. An older app must keep drawing the badges it
    // knows rather than failing the whole call over a word it has never seen.
    expect(unknown, isNull);
  });

  test('a count of zero and a missing key read the same', () {
    // Arrange
    const counts = <CustomerBadge, int>{};

    // Act & Assert — the tile asks `countOf` and draws nothing at zero, so a badge that has
    // never been fetched and one that has just been cleared look identical, which is right.
    expect(counts.countOf(CustomerBadge.support), 0);
    expect(counts.has(CustomerBadge.support), isFalse);
    expect({CustomerBadge.support: 0}.has(CustomerBadge.support), isFalse);
    expect({CustomerBadge.support: 2}.has(CustomerBadge.support), isTrue);
  });
}
