import 'dart:io';

import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mechanical guard on one ticket status having one name.
///
/// A ticket on screen always draws the server's own `status_label`, so *that* cannot drift.
/// What can drift is the two hand-copies this app keeps of the same vocabulary: the
/// `@JsonValue` on each [TicketStatus] case, and the Arabic [TicketStatusX.label] prints on the
/// filter chips. Both were typed here by hand, in a different language, with no compiler
/// watching either side.
///
/// **The wire check runs through `SupportTicket.fromJson`, not over a list of strings.** An
/// annotation cannot be read at runtime, so the only honest way to ask "does this build decode
/// `in_progress`?" is to hand it `in_progress` and look at what comes back. That distinction is
/// not academic: `json_serializable` encodes by the *member name* unless told otherwise, and
/// this repository has already shipped an enum where `underReview` silently decoded to nothing
/// and a notice never once appeared on screen. A test comparing string literals to string
/// literals would have passed through that bug without a word.
///
/// So this test reads the PHP enum. Both repositories live in one workspace, which makes it
/// free — and when the backend is not checked out it **skips** rather than fails, so a
/// frontend-only checkout still goes green. The same arrangement as
/// `order_status_contract_test.dart`, for the same reason.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/app/Domain/Support/Enums/TicketStatus.php');

  /// `case Open = 'open';` — every status the backend defines, in declaration order.
  List<String> wires(String php) => RegExp(r"case \w+ = '([^']+)';")
      .allMatches(php)
      .map((match) => match.group(1)!)
      .toList();

  /// The Arabic each one is given, read out of `label()` alone.
  ///
  /// Scoped to that method on purpose: a regex over the whole file would also read the
  /// docblocks, which quote «مفتوحة» and «قيد المعالجة» while explaining why the middle case
  /// earns its place.
  Map<String, String> labels(String php) {
    final method = php.substring(
      php.indexOf('public function label(): string'),
      php.indexOf('public function isOpen'),
    );

    final byCase = <String, String>{};

    for (final match in RegExp(r"self::(\w+) => '([^']+)'").allMatches(method)) {
      byCase[match.group(1)!] = match.group(2)!;
    }

    // `Open` is declared as `case Open = 'open';` — pair the case name back to its wire so the
    // label can be looked up by the value that actually crosses the network.
    final wireFor = <String, String>{
      for (final match in RegExp(r"case (\w+) = '([^']+)';").allMatches(php))
        match.group(1)!: match.group(2)!,
    };

    return {
      for (final entry in byCase.entries) wireFor[entry.key]!: entry.value,
    };
  }

  /// A ticket carrying one status and nothing else worth reading.
  TicketStatus decode(String wire) => SupportTicket.fromJson(<String, dynamic>{
    'id': 1,
    'subject': 'سؤال',
    'status': wire,
    'status_label': 'أيًّا كان',
  }).status;

  test('every status the backend defines decodes, and none lands on unknown', () {
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this app');

      return;
    }

    // Arrange
    final php = source.readAsStringSync();

    // Act
    final decoded = {for (final wire in wires(php)) wire: decode(wire)};

    // Assert — `unknown` here is the whole failure mode: it is what an *unrecognised* word
    // decodes to, so a status landing on it means this build cannot read a word the server is
    // already sending, and the queue would draw it under the wrong chip.
    expect(decoded, isNotEmpty, reason: 'the regex found no cases — has the enum been renamed?');

    decoded.forEach((wire, status) {
      expect(
        status,
        isNot(TicketStatus.unknown),
        reason: "the server sends '$wire' and this build does not recognise it",
      );
    });
  });

  test('the chips offer exactly the statuses the backend has', () {
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this app');

      return;
    }

    // Arrange
    final php = source.readAsStringSync();

    // Act
    final offered = offerableTicketStatuses;

    // Assert — a status this app invented would be a chip asking the server for a value it
    // will refuse; one it is missing is a chip the desk never gets.
    expect(
      offered.length,
      wires(php).length,
      reason: 'the filter chips and the backend enum are different lengths',
    );
  });

  test('the Arabic on the chips is the Arabic the server uses', () {
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this app');

      return;
    }

    // Arrange
    final php = source.readAsStringSync();
    final expected = labels(php);

    // Act
    final actual = {
      for (final entry in expected.entries) entry.key: decode(entry.key).label,
    };

    // Assert — the drift this catches is «مغلقة» on one side and «منتهية» on the other, which
    // no compiler and no running app would ever complain about.
    expect(actual, expected);
  });
}
