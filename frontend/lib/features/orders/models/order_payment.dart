import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_payment.freezed.dart';
part 'order_payment.g.dart';

/// What a ledger entry *is*.
///
/// Four, and each is a different sentence about the same amount. Money going back out is either a
/// **refund** — cash genuinely handed over — or a **reversal**, which says a row was a mistake and
/// describes nothing that happened. They subtract the same figure and mean entirely different
/// things.
///
/// The fourth says money is not coming at all: a **write-off** closes what is left of a debt
/// without any cash moving, which is why it never touches «المدفوع».
enum OrderPaymentType {
  @JsonValue('payment')
  payment,

  @JsonValue('reversal')
  reversal,

  @JsonValue('refund')
  refund,

  /// The difference the business decided not to chase — see [OrderPayment.isIncoming].
  @JsonValue('write_off')
  writeOff,

  /// A type this build has not been taught. The server's own `type_label` is what gets drawn,
  /// so an entry added after this release still reads correctly — see [OrderPayment.typeLabel].
  unknown,
}

/// How the money moved.
///
/// The labels here are never rendered: the server sends `method_label` with every entry and that
/// is what the screen shows. These exist so the *form* can offer the four, and so
/// [requiresReceipt] can be asked before the request is sent rather than after it is refused.
enum PaymentMethod {
  @JsonValue('cash')
  cash('cash', 'كاش'),

  @JsonValue('bank_transfer')
  bankTransfer('bank_transfer', 'حوالة'),

  @JsonValue('bank_card')
  bankCard('bank_card', 'بطاقة مصرفية'),

  @JsonValue('libyana')
  libyana('libyana', 'ليبيانا'),

  /// A method this build has not been taught. Never offered in the form — see [selectable] —
  /// and never blocks an entry from being read: `method_label` is what gets drawn, so a method
  /// added after this release still renders correctly on an old phone.
  unknown('', 'غير معروفة');

  const PaymentMethod(this.wire, this.label);

  final String wire;
  final String label;

  /// The four a person may actually choose.
  static List<PaymentMethod> get selectable =>
      values.where((method) => method != PaymentMethod.unknown).toList(growable: false);

  /// Whether an entry paid this way must carry its receipt (الواصل).
  ///
  /// **A courtesy, never the boundary.** The server refuses a transfer without one, and a
  /// database CHECK refuses it underneath that. This copy exists so the form can put the file
  /// field in front of somebody *before* they fill the rest in — being told at the counter that
  /// the paper is missing is the point, and being told after pressing save is a wasted trip.
  bool get requiresReceipt => this == PaymentMethod.bankTransfer;
}

/// Where an order stands on its money.
///
/// Derived on the server from what has been paid against what the order costs — there is no
/// column, deliberately, because the total moves whenever the lines or a discount do.
enum PaymentStatus {
  @JsonValue('unpaid')
  unpaid('unpaid', 'غير مدفوعة'),

  @JsonValue('partially_paid')
  partiallyPaid('partially_paid', 'مدفوعة جزئياً'),

  @JsonValue('paid')
  paid('paid', 'مدفوعة بالكامل'),

  /// More paid than the order costs. Not a mistake that got through — a discount landed after
  /// the money did — and it is shown so somebody can refund the difference.
  @JsonValue('overpaid')
  overpaid('overpaid', 'مدفوعة بالزيادة'),

  /// Nothing is owed any more, and part of what closed it was never collected.
  ///
  /// Its own state rather than «مدفوعة بالكامل», because the two are different facts: an order
  /// of 110 that took 105 and had the difference written off owes nothing — so it belongs
  /// nowhere near the queue somebody chases — but it was not paid in full, and saying so would
  /// be the lie the write-off exists to avoid telling.
  @JsonValue('written_off')
  writtenOff('written_off', 'مشطوب فرقها'),

  unknown('', 'غير معروفة');

  const PaymentStatus(this.wire, this.label);

  /// Exactly the string the API sends and `payment_status[]` takes.
  final String wire;

  /// **Only for the filter, which has no order in hand to read a label from.** Everywhere an
  /// order is on screen the server's own `payment_status_label` is what gets drawn, so a state
  /// added later still reads correctly — see [PaymentSummary.paymentStatusLabel].
  final String label;

  /// The three a person filters by.
  ///
  /// «مدفوعة بالزيادة» is absent deliberately: it is not a queue anybody works, it arises only
  /// from a discount granted after payment, and a fourth row would push the three that matter
  /// down the sheet. An overpaid order still says so on its own card.
  static List<PaymentStatus> get filterable => const [
    PaymentStatus.paid,
    PaymentStatus.partiallyPaid,
    PaymentStatus.unpaid,
  ];
}

/// One entry in an order's money ledger.
///
/// **Never edited and never deleted, on either side of the wire.** There is no endpoint that
/// updates one, and this model has no `copyWith` call anywhere that writes back: a mistake is
/// undone by a second entry that points at the first, so the wrong row and its correction are
/// both on screen. A ledger you can rewrite explains nothing.
///
/// **Every money field is a `String`.** `'150.00'` as the server sent it — a `double` stops being
/// the number the receipt printed the moment it is parsed, and these are summed.
@freezed
abstract class OrderPayment with _$OrderPayment {
  const factory OrderPayment({
    required int id,
    @JsonKey(name: 'order_id') required int orderId,

    @JsonKey(unknownEnumValue: OrderPaymentType.unknown) required OrderPaymentType type,

    /// The Arabic the server chose. Rendered as-is, so an entry type this build does not know
    /// still reads correctly.
    @JsonKey(name: 'type_label') required String typeLabel,

    /// Always positive. Which direction it moves is [type]'s business — see [isIncoming].
    required String amount,

    /// **The two flags the ledger is drawn from**, both decided by the server. `isReversed`
    /// strikes the row through; `isReversible` is what puts a cancel action on it — and the
    /// server has already decided that a refund and a reversal are not candidates, so this
    /// screen keeps no copy of that rule.
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,
    @JsonKey(name: 'is_reversible') @Default(false) bool isReversible,

    /// Whether the receipt (الواصل) is on file. Always true on a transfer, which is the one
    /// method that cannot be recorded without one.
    @JsonKey(name: 'has_receipt') @Default(false) bool hasReceipt,

    /// Whether the receipt is a picture this app can draw full screen, as opposed to a PDF it
    /// hands to the phone. **Decided by the server** from the file it actually stored, so no
    /// copy of the format list lives in Dart.
    @JsonKey(name: 'receipt_is_image') @Default(false) bool receiptIsImage,

    /// Null on a reversal alone: no money moved, so there is no method to name.
    @JsonKey(unknownEnumValue: PaymentMethod.unknown) PaymentMethod? method,
    @JsonKey(name: 'method_label') String? methodLabel,

    /// The receipt or transfer number, when there is one.
    String? reference,

    /// A link to the receipt PDF, built per request by the server.
    ///
    /// **Expires**, and is not stored: the disk is private, because a receipt carries somebody's
    /// bank details. Fetch it when it is opened, never hold it.
    @JsonKey(name: 'receipt_url') String? receiptUrl,
    @JsonKey(name: 'receipt_filename') String? receiptFilename,
    @JsonKey(name: 'receipt_size_bytes') int? receiptSizeBytes,

    String? notes,

    /// Which entry this one undoes, on a reversal.
    @JsonKey(name: 'reverses_payment_id') int? reversesPaymentId,

    /// And the other way round, so a struck-through row can name its own correction without
    /// the screen pairing rows up by eye.
    OrderPaymentReversal? reversal,

    /// Who took it. Absent on an entry written by a console command or a seeder.
    @JsonKey(name: 'recorder') PaymentRecorder? recordedBy,

    /// **When the money moved**, not when it was typed in — the two genuinely differ on a
    /// deposit taken on Thursday and entered on Saturday. [createdAt] answers the other one.
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderPayment;

  const OrderPayment._();

  factory OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);

  /// Whether this entry added to what the order has been paid.
  ///
  /// A write-off is deliberately not incoming: it closes a debt, and no money arrived.
  bool get isIncoming => type == OrderPaymentType.payment;

  /// Whether this entry closed part of the debt without any money moving.
  bool get isWriteOff => type == OrderPaymentType.writeOff;

  /// Whether this entry counts for nothing any more — struck through on screen.
  bool get isVoid => isReversed || type == OrderPaymentType.reversal;
}

/// The reversal that undid an entry, as much of it as the row above needs to name it.
@freezed
abstract class OrderPaymentReversal with _$OrderPaymentReversal {
  const factory OrderPaymentReversal({
    required int id,

    /// Why it was cancelled. Required by the server, so it is never blank on a real entry.
    String? reason,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderPaymentReversal;

  factory OrderPaymentReversal.fromJson(Map<String, dynamic> json) =>
      _$OrderPaymentReversalFromJson(json);
}

/// Who wrote an entry.
@freezed
abstract class PaymentRecorder with _$PaymentRecorder {
  const factory PaymentRecorder({
    required int id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
  }) = _PaymentRecorder;

  factory PaymentRecorder.fromJson(Map<String, dynamic> json) => _$PaymentRecorderFromJson(json);
}

/// An order's money, in the shape the screen puts side by side.
///
/// **Every number here is the server's arithmetic, including the subtraction.** The remaining
/// amount is not `grandTotal - paidAmount` computed on the phone: that would be a second answer
/// to one question, and the phone's is the one made of doubles.
@freezed
abstract class PaymentSummary with _$PaymentSummary {
  const factory PaymentSummary({
    @JsonKey(name: 'grand_total') required String grandTotal,
    @JsonKey(name: 'paid_amount') required String paidAmount,

    /// What was closed without being collected — the five dinars that never came back.
    ///
    /// **Beside «المدفوع» and never inside it**, so that number goes on meaning cash. Defaulted
    /// rather than required: an app talking to a server from before this existed reads a zero,
    /// which is exactly what such a server means.
    @JsonKey(name: 'written_off_amount') @Default('0.00') String writtenOffAmount,

    /// What is still owed. **Negative when the order is overpaid**, so the screen can say
    /// «زائد ٥٠» rather than flooring the fact away.
    @JsonKey(name: 'remaining_amount') required String remainingAmount,

    @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)
    required PaymentStatus paymentStatus,

    @JsonKey(name: 'payment_status_label') required String paymentStatusLabel,

    /// An order that finished without its money accounted for.
    ///
    /// Settling an order writes no ledger entry — nothing records a payment except the person
    /// who took it — so this is how that gap is surfaced instead of being papered over with an
    /// entry nobody made. The screen shows a warning; somebody records what was collected.
    @JsonKey(name: 'has_unrecorded_money') @Default(false) bool hasUnrecordedMoney,
  }) = _PaymentSummary;

  const PaymentSummary._();

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => _$PaymentSummaryFromJson(json);

  /// Whether anything is still owed — the one question the colour of «المتبقي» answers.
  ///
  /// A written-off order is **not** outstanding: the debt was closed by a decision somebody made
  /// and signed. A worse outcome than being paid, but not an open balance.
  bool get isOutstanding =>
      paymentStatus == PaymentStatus.unpaid || paymentStatus == PaymentStatus.partiallyPaid;

  /// Whether any of this order's debt was forgiven rather than collected.
  ///
  /// Asked of the *number* rather than of [paymentStatus], because a partial write-off leaves
  /// the order still owing — «مدفوعة جزئياً» with five already written off is a real state, and
  /// the screen still owes the reader that line.
  bool get hasWriteOff => writtenOffAmount != '0.00' && writtenOffAmount.isNotEmpty;
}

/// What the ledger endpoint answers with: the entries, and where the order stands after them.
@freezed
abstract class OrderLedger with _$OrderLedger {
  const factory OrderLedger({
    required List<OrderPayment> payments,
    required PaymentSummary summary,
  }) = _OrderLedger;

  factory OrderLedger.fromJson(Map<String, dynamic> json) => _$OrderLedgerFromJson(json);
}
