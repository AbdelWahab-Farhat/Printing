import 'package:freezed_annotation/freezed_annotation.dart';

part 'transition_field.freezed.dart';
part 'transition_field.g.dart';

/// The kinds of input a status change can ask for.
///
/// **The app draws a widget per kind, so this list is the one thing the two sides must share.**
/// A *field* added to a move on the server needs nothing here — it arrives, and the widget for
/// its kind renders it. A *kind* the server invents does need a release, and until it lands
/// [unknown] is what keeps the rest of the form usable instead of failing to parse the order.
enum TransitionFieldType {
  @JsonValue('text')
  text,

  /// A quantity — kilograms off a scale, pieces off a press. Carries [min] and [max], which are
  /// facts about *this* order rather than rules the app could know.
  @JsonValue('number')
  number,

  /// Versions of the artwork, chosen from the customer's own library — and uploaded into it
  /// first when the file is new. What travels to the server is only ever the design's id.
  @JsonValue('customer_designs')
  customerDesigns,

  /// One of the carriers the business maintains.
  ///
  /// No options arrive with the field: this app already owns that list — it manages it — so the
  /// picker fetches the active companies itself and only the id travels back.
  @JsonValue('shipping_company')
  shippingCompany,

  /// Which store the run's stock comes out of.
  ///
  /// Like the carrier, no options arrive with it — the app manages the list of warehouses, so
  /// the picker fetches them itself and only the id travels back. Asked on the way into «قيد
  /// الطباعة», and required exactly once: a reprint that has already emptied a shelf is offered
  /// the field but not made to answer it again.
  @JsonValue('warehouse')
  warehouse,

  /// A kind this build has no widget for. Rendered as a note rather than silently skipped: a
  /// field the server thinks is required and the screen never shows is a form that cannot be
  /// submitted with nothing on screen to explain why.
  unknown,
}

/// One thing a move asks the person making it for.
///
/// **Written by the server, on the transition itself.** The screen renders exactly what it was
/// handed — no list of "designing needs artwork" in Dart — which is what makes adding a field to
/// a path a change on one side. See `TransitionFields` on the backend.
@freezed
abstract class TransitionField with _$TransitionField {
  const factory TransitionField({
    /// What the value is sent back as, inside `fields`.
    required String key,

    @JsonKey(unknownEnumValue: TransitionFieldType.unknown)
    required TransitionFieldType type,

    /// The Arabic the server chose. Rendered as-is, like every other label in this app.
    required String label,

    @JsonKey(name: 'required') @Default(false) bool isRequired,

    /// The field takes several values. Only meaningful for kinds that can hold more than one.
    @Default(false) bool multiple,

    /// A text field of several lines rather than one.
    @Default(false) bool multiline,

    /// A sentence under the field, when the server has something to say about it.
    String? hint,

    /// Bounds for [TransitionFieldType.number]. [max] is typically what was ordered of one
    /// line — «الناقص من 30*30» can never exceed it — so it travels with the field.
    num? min,
    num? max,

    /// What the box opens holding — **an answer, not a placeholder.**
    ///
    /// Leaving «نواقص» asks how much of the shortage arrived, and nearly always the answer is
    /// all of it: the server fills that in, and agreeing costs a tap. Null on almost every
    /// field, because a box that suggests a wrong number is worse than an empty one.
    String? value,
  }) = _TransitionField;

  const TransitionField._();

  factory TransitionField.fromJson(Map<String, dynamic> json) =>
      _$TransitionFieldFromJson(json);

  /// Whether this build can put a control on screen for it.
  bool get isRenderable => type != TransitionFieldType.unknown;
}
