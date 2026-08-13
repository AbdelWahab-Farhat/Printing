import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/transition_field.dart';

/// The mechanical guard on a *kind* of field the server can ask for.
///
/// **This is the one contract in the transition machinery that a release can break silently.**
/// A new *field* on a move needs nothing here — it arrives described and the widget for its kind
/// draws it. A new *kind* is different: [TransitionFieldType.unknown] catches it, so nothing
/// fails to parse and no test goes red, and the screen quietly renders a note where an input
/// should be. If the server marked that field required, the move becomes unmakeable from the
/// app and the only symptom is a 422 nobody can act on.
///
/// That is exactly what happened when `warehouse` was added for «قيد الطباعة»: the safety net
/// worked as designed, and the path every order takes could not be walked.
///
/// So the PHP enum is read directly. Both repositories live in one workspace, which makes it
/// free — and when the backend is not checked out it **skips** rather than fails, the same
/// arrangement `order_status_contract_test.dart` uses, for the same reason.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/app/Domain/Order/Enums/TransitionFieldType.php');

  /// `case Warehouse = 'warehouse';` — every kind the backend can send.
  Set<String> wires(String php) => RegExp("case \\w+ = '([^']+)';")
      .allMatches(php)
      .map((match) => match.group(1)!)
      .toSet();

  test('every kind of field the backend can send has a widget in this app', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act
    final backend = wires(source.readAsStringSync());
    // `unknown` is this app's own: it is what a kind this build has never heard of parses as,
    // so it deliberately has no counterpart over there.
    final app = TransitionFieldType.values
        .where((type) => type != TransitionFieldType.unknown)
        .map((type) => type.name)
        .toSet();

    // Assert — compared on the *wire* values, so the two sides are matched by what actually
    // crosses the network rather than by a Dart name that happens to look similar.
    expect(
      backend,
      isNotEmpty,
      reason: 'the regex matched nothing — did the PHP file change shape?',
    );
    expect(
      backend.difference(_wireValues),
      isEmpty,
      reason:
          'the backend can send a field kind this app has no case for — it would render as '
          '«unknown», and a required one would make the move unmakeable',
    );
    expect(
      _wireValues.difference(backend),
      isEmpty,
      reason: 'this app knows a field kind the backend never sends',
    );
    expect(app, hasLength(_wireValues.length));
  });
}

/// The wire value of every kind this build can draw.
///
/// Written out rather than derived: `@JsonValue` is an annotation, and there is no way to read
/// one back off an enum at runtime. Keeping the list here means adding a case without adding it
/// to this set is itself a failure — which is the point.
const Set<String> _wireValues = {
  'text',
  'number',
  'customer_designs',
  'shipping_company',
  'warehouse',
};
