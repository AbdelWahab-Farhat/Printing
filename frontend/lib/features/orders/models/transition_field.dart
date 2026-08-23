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
  /// the picker fetches them itself and only the id travels back. Asked on the way into
  /// «جاهزة», which is where stock leaves the shelf, and required exactly once: an order whose
  /// stock has already gone is offered the field but not made to answer it again.
  ///
  /// **Which move asks for it is the server's to decide, and this comment is not load-bearing.**
  /// It used to be «قيد الطباعة»; the screen followed the change without a line of Dart, because
  /// it renders `available_transitions[].fields` as sent and holds no map of its own.
  @JsonValue('warehouse')
  warehouse,

  /// How the money taken during the move was handed over.
  ///
  /// **The one kind whose choices arrive with it**, in [TransitionField.options]. The carrier
  /// and warehouse lists are this app's own, so it fetches those itself — but which payment
  /// methods are usable *on this screen* is the server's call, not the business's: «حوالة»
  /// obliges a receipt and a status change uploads no files, so it is not among them. Reading
  /// the app's own `PaymentMethod` here would offer four and be refused on the fourth.
  @JsonValue('payment_method')
  paymentMethod,

  /// A document or a photograph, uploaded with the move.
  ///
  /// **The one kind that changes how the move is sent.** A file cannot travel in a JSON body,
  /// so a transition carrying one goes up as multipart — see `OrderRepositoryImpl.changeStatus`.
  /// What the endpoint will accept arrives with the field in [TransitionField.extensions] and
  /// [TransitionField.maxKilobytes], so a doomed file is refused here rather than after an
  /// upload the person waited through, and this app keeps no copy of `config/media.php`.
  @JsonValue('file')
  file,

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

    /// The choices, for the one kind that carries its own — see
    /// [TransitionFieldType.paymentMethod]. Empty for every other kind.
    @Default(<TransitionFieldOption>[]) List<TransitionFieldOption> options,

    /// The field-and-answer that makes this one mandatory — the sibling of [requiredWith], for
    /// a rule that turns on a *particular* answer rather than on any answer at all.
    ///
    /// «الواصل» is optional beside a card and obligatory beside a transfer, and which of the two
    /// is decided by a chip on the same screen. Sent down so the day a fourth method starts
    /// obliging one, this app follows with no release.
    @JsonKey(name: 'required_if') TransitionFieldCondition? requiredIf,

    /// What a [TransitionFieldType.file] will accept — the endpoint's own limits, so nothing
    /// here restates `config/media.php`.
    @Default(<String>[]) List<String> extensions,
    @JsonKey(name: 'max_kilobytes') int? maxKilobytes,

    /// The key of the field that makes this one mandatory: empty is fine on its own, and
    /// refused the moment that other field is answered.
    ///
    /// «طريقة الدفع» is meaningless without an amount and obligatory with one, and neither
    /// [isRequired] nor its absence can say that. Sent down so [canSubmit] can hold the same
    /// rule the endpoint enforces rather than this app keeping a second copy of it.
    @JsonKey(name: 'required_with') String? requiredWith,

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

  /// Whether this field has to be answered, given everything else on the form.
  ///
  /// [isRequired] alone is not the whole rule: a field may be optional in itself and obligatory
  /// once its [requiredWith] partner is filled in. Asked of the values rather than of the field
  /// so that clearing the amount releases the method again.
  bool isDemandedBy(Map<String, Object?> values) {
    if (isRequired) return true;

    if (requiredWith case final partner? when _isAnswered(values[partner])) return true;

    if (requiredIf case final condition?) {
      return values[condition.key] == condition.value;
    }

    return false;
  }

  static bool _isAnswered(Object? value) => switch (value) {
    null => false,
    final String text => text.trim().isNotEmpty,
    final Iterable<Object?> many => many.isNotEmpty,
    _ => true,
  };

  /// Why this file cannot be attached, in the words the server would have used — or null.
  ///
  /// **The server's own limits, applied before the upload rather than after it.** Pushing a
  /// doomed file over a Libyan mobile connection to be told it is the wrong kind is a person's
  /// time and data allowance spent to learn something knowable instantly. Nothing is duplicated
  /// to do it: [extensions] and [maxKilobytes] came down with the field.
  String? rejectFile(String filename, int sizeBytes) {
    final dot = filename.lastIndexOf('.');
    final extension = dot == -1 ? '' : filename.substring(dot + 1).toLowerCase();

    if (extensions.isNotEmpty && !extensions.contains(extension)) {
      return '$label يجب أن يكون بصيغة ${extensions.map((e) => e.toUpperCase()).join(' أو ')}';
    }

    if (maxKilobytes case final limit? when sizeBytes > limit * 1024) {
      return 'حجم $label يجب ألا يتجاوز ${limit ~/ 1024} ميجابايت';
    }

    return null;
  }
}

/// «هذا الحقل مطلوب حين تكون إجابة ذاك كذا» — a rule the server states and this app applies.
@freezed
abstract class TransitionFieldCondition with _$TransitionFieldCondition {
  const factory TransitionFieldCondition({
    required String key,
    required String value,
  }) = _TransitionFieldCondition;

  factory TransitionFieldCondition.fromJson(Map<String, dynamic> json) =>
      _$TransitionFieldConditionFromJson(json);
}

/// One choice on a field that carries its own list.
///
/// Both halves come from the server: [value] is what crosses the wire and [label] is the Arabic
/// drawn on the chip. The app translates neither — the same rule every other label on this
/// screen follows.
@freezed
abstract class TransitionFieldOption with _$TransitionFieldOption {
  const factory TransitionFieldOption({
    required String value,
    required String label,
  }) = _TransitionFieldOption;

  factory TransitionFieldOption.fromJson(Map<String, dynamic> json) =>
      _$TransitionFieldOptionFromJson(json);
}
