/// Keyboard-side rules for a field that holds a number.
///
/// **A formatter, not a validator, and the two are not interchangeable.** A validator complains
/// after the fact, under a field the user has already finished with; a formatter refuses the
/// keystroke that would have been wrong. Both exist here — see [Validators] for the other half —
/// and a rule that can be expressed at the keyboard belongs at the keyboard.
library;

import 'package:dayaa_client/core/utils/validators.dart';
import 'package:flutter/services.dart';

/// Turns ١٢٣ and ۱۲۳ into 123 **as they are typed**.
///
/// **Because refusing them is the bug.** The quantity field used to filter on `[0-9.]`, which is
/// ASCII, so a customer on an Arabic keyboard pressed ٥ and watched nothing appear — the one
/// failure a person cannot diagnose, because the field gives no reason and looks broken.
/// `validators.dart` has said so in a comment since it was written; nothing acted on it.
///
/// **The selection survives** because the conversion is one rune for one rune: every Arabic-Indic
/// and Persian digit maps to a single ASCII digit and `٫` to `.`, so the text never changes
/// length and the cursor offset stays where the user left it. A conversion that inserted or
/// dropped characters would have to move the selection with them.
class WesternDigitsInputFormatter extends TextInputFormatter {
  const WesternDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final converted = Validators.toWesternDigits(newValue.text);

    if (converted == newValue.text) return newValue;

    return TextEditingValue(
      text: converted,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

/// A quantity: digits, and at most one decimal point when the product is sold by a unit that can
/// be divided.
///
/// **It refuses the edit rather than filtering the text**, which is the difference between this
/// and the `FilteringTextInputFormatter.allow([0-9.])` it replaces. Filtering kept every
/// character that was individually allowed, so `1.2.3` and `...` were each built one legal
/// keystroke at a time and reached the server as things that are not numbers. Judging the whole
/// string instead means a keystroke is only accepted if what it leaves behind is still a
/// quantity.
///
/// **[wholeOnly] is the catalogue's rule read forward.** A product priced «قطعة» cannot be
/// ordered in halves — `PricingUnit::requiresWholeQuantities()` on the server, and
/// `RequestOrderRequest` refuses 2.5 of one — while a product priced «كجم» is *ordinarily*
/// fractional and 7.5 is exactly what somebody means. So the dot is not forbidden, it is
/// forbidden *here*: one rule, asked of the product in hand.
///
/// **A digit has to come first.** `.` on its own is not a quantity part-way to being typed, it is
/// a quantity that will be added to the basket and refused at the till — the server reads `.` as
/// nothing (`is_numeric('.')` is false) and answers 422 after a round trip nobody needed. `.5` is
/// refused with it, and `0.5` is the way to say that; the field opens on the product's minimum,
/// so it is never empty to begin with.
///
/// A trailing `100.` *is* allowed, and has to be: it is the only road to `100.5`. That one is
/// harmless where `.` is not — the server reads it as 100.
class QuantityInputFormatter extends TextInputFormatter {
  const QuantityInputFormatter({required this.wholeOnly});

  /// Whether the product is sold by something that cannot be halved.
  final bool wholeOnly;

  static final RegExp _whole = RegExp(r'^\d+$');
  static final RegExp _fractional = RegExp(r'^\d+\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final shape = wholeOnly ? _whole : _fractional;

    // Clearing the field is always allowed: a customer replacing a quantity empties it first,
    // and a formatter that refused that would trap them at the old number.
    if (newValue.text.isEmpty) return newValue;

    return shape.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
