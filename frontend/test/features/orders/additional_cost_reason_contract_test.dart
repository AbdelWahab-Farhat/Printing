import 'dart:io';

import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:flutter_test/flutter_test.dart';

/// [AdditionalCostReason] against `AdditionalCostReason.php`, code for code and word for word.
///
/// **The one that matters most on this feature.** A chip posting `packaging` where the server
/// says `special_packaging` is a 422 about a field the clerk *did* fill in — the worst kind of
/// refusal, because the screen looks correct. And the Arabic is drawn from here rather than from
/// an order (there is no order yet when the five chips are drawn), so a word that drifts is a
/// word only this app is saying.
///
/// Both repositories live in one workspace, which makes this free — and when the backend is not
/// checked out it **skips** rather than fails, so a frontend-only checkout still goes green.
/// The same arrangement `order_status_contract_test.dart` uses.
///
/// Arrange - Act - Assert.
void main() {
  final source = File('../backend/app/Domain/Order/Enums/AdditionalCostReason.php');

  /// `case SpecialPackaging = 'special_packaging';` → PHP case name → wire code.
  Map<String, String> casesIn(String php) => {
    for (final match in RegExp(r"case (\w+) = '([^']+)';").allMatches(php))
      match.group(1)!: match.group(2)!,
  };

  /// `self::SpecialPackaging => 'تغليف خاص',` → PHP case name → Arabic.
  Map<String, String> labelsIn(String php) => {
    for (final match in RegExp(r"self::(\w+) => '([^']+)',").allMatches(php))
      match.group(1)!: match.group(2)!,
  };

  test('every category the server knows is a chip here, with the same code', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act
    final backend = casesIn(source.readAsStringSync()).values.toSet();
    final app = AdditionalCostReason.choices.map((reason) => reason.wire).toSet();

    // Assert — named in each direction: one failure is a case to add, the other is one to
    // delete, and `unknown` is deliberately not among the choices.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing — did the PHP change shape?');
    expect(app, backend);
    expect(AdditionalCostReason.unknown.wire, isEmpty);
    expect(AdditionalCostReason.choices, isNot(contains(AdditionalCostReason.unknown)));
  });

  test('the Arabic on the chips is the Arabic the server labels the order with', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    final php = source.readAsStringSync();
    final codes = casesIn(php);
    final labels = labelsIn(php);

    // Act — PHP wire code → its Arabic, as the server would answer it.
    final backend = {
      for (final entry in codes.entries) entry.value: ?labels[entry.key],
    };

    // Assert — an order on screen shows `additional_cost_reason_label`; the chips show these.
    // The two disagreeing is «تغليف خاص» on the invoice and something else on the form.
    expect(
      {for (final reason in AdditionalCostReason.choices) reason.wire: reason.label},
      backend,
    );
  });

  test('«أخرى» is the one that cannot stand without words, here as there', () {
    // Arrange
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act — `return $this === self::Other;` is the whole of the PHP's `needsNote()`.
    final php = source.readAsStringSync();
    final needsNote = RegExp(r'needsNote\(\): bool\s*\{\s*return \$this === self::(\w+);')
        .firstMatch(php)
        ?.group(1);

    // Assert
    expect(needsNote, 'Other');
    expect(
      AdditionalCostReason.choices.where((reason) => reason.needsNote),
      [AdditionalCostReason.other],
    );
  });
}
