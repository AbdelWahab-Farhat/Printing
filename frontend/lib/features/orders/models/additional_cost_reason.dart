import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Why an order is being charged more than its products come to.
///
/// **A closed set rather than a free-text box**, and the reason is the server's: this figure is
/// money the business collects, and the question asked of collected money is eventually «كم
/// حصّلنا مقابل التغليف هذا الربع؟». A column filled by hand answers that with «تغليف»، «تغليف
/// خاص»، «كرتون» and «تغليف!!» — four spellings of one category and no way to group them. So the
/// category is a code and the words beside it are the detail.
///
/// **[label] is for the form and nothing else.** An order on screen shows the server's
/// `additional_cost_reason_label`, exactly as it shows `status_label`; this Arabic exists for the
/// one place that has no order to read a word from — the five chips drawn before anything has
/// been saved. Same split, and same reason, as [OrderStatus.label].
///
/// Mirrors `AdditionalCostReason.php`, and `additional_cost_reason_contract_test.dart` fails if
/// any code or word here drifts from the one over there — a chip posting `packaging` where the
/// server says `special_packaging` is a 422 about a field the clerk did fill in.
enum AdditionalCostReason {
  /// A box, a wrap, a bag inside the bag — anything the goods travel in that was asked for.
  @JsonValue('special_packaging')
  specialPackaging('special_packaging', 'تغليف خاص'),

  /// Work done for this customer that no line on the order describes.
  @JsonValue('extra_service')
  extraService('extra_service', 'خدمة إضافية'),

  /// A change to what was already agreed, charged rather than absorbed.
  @JsonValue('modification')
  modification('modification', 'تعديل'),

  /// Moving the goods somewhere the delivery price does not cover.
  @JsonValue('transport')
  transport('transport', 'نقل'),

  /// Everything the four above do not name — and the one case that *requires* words of its own,
  /// because «أخرى» on its own carries no information at all.
  @JsonValue('other')
  other('other', 'أخرى'),

  /// A category this build has never heard of.
  ///
  /// Same escape hatch [OrderStatus.unknown] is: a sixth reason added on the server must not
  /// stop an order from parsing. It is never offered as a choice and never sent — the order
  /// still prints the label the server put beside it.
  unknown('', 'غير معروف');

  const AdditionalCostReason(this.wire, this.label);

  /// The code the API speaks.
  final String wire;

  /// The Arabic the chips are drawn with. Never used to render an order — see the class note.
  final String label;

  /// The five a person may pick, in the order the server declares them.
  static List<AdditionalCostReason> get choices =>
      values.where((reason) => reason != unknown).toList(growable: false);

  /// Whether this category is meaningless without words beside it.
  bool get needsNote => this == other;
}
