import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

/// Where a thread stands.
///
/// **`unknown` is not a state the business has** — it is what a status added to the API after
/// this build shipped decodes to, so a new word on the server cannot crash the queue. Every
/// case carries its `@JsonValue`, including the ones whose Dart name happens to match today:
/// `json_serializable` encodes by the *member name* unless told otherwise, and a spelling that
/// agrees by accident is not a spelling anybody checked.
enum TicketStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('closed')
  closed,

  /// A status added to the API after this build shipped.
  unknown,
}

/// The statuses a person may filter by — every real one, and never [TicketStatus.unknown].
///
/// **Derived from `values`, not written out.** A fourth status added to this enum joins the
/// chips by existing, which is the whole point: a hand-kept list here would agree on the day it
/// was typed and silently omit the next one.
final List<TicketStatus> offerableTicketStatuses = TicketStatus.values
    .where((status) => status != TicketStatus.unknown)
    .toList(growable: false);

extension TicketStatusX on TicketStatus {
  bool get isClosed => this == TicketStatus.closed;

  /// The Arabic for this status.
  ///
  /// **A ticket on screen never uses this** — it draws `status_label`, which travels with the
  /// row so a status added to the business needs no app release. This exists for the one place
  /// that has no row to read a label off: the filter chips, which name statuses the queue might
  /// contain rather than statuses it does.
  ///
  /// So it is a hand-copy of the server's `label()`, and `ticket_status_contract_test` is what
  /// stops it drifting — the same arrangement `OrderStatus` has for the same reason.
  String get label => switch (this) {
    TicketStatus.open => 'مفتوحة',
    TicketStatus.inProgress => 'قيد المعالجة',
    TicketStatus.closed => 'مغلقة',

    // Never offered as a filter — asking the server for a status this build cannot name would
    // send the word `unknown` as a query parameter. Present so the switch stays total.
    TicketStatus.unknown => 'غير معروف',
  };

  /// Whether the desk can still write into it. The server refuses a reply on a closed ticket —
  /// unlike a customer's, which reopens it — so the composer is hidden rather than left to be
  /// refused.
  bool get acceptsReplies => this != TicketStatus.closed;
}

/// Who said it.
enum MessageAuthor {
  @JsonValue('customer')
  customer,
  @JsonValue('staff')
  staff,

  /// A value this build has not heard of. Drawn as the shop's side, which is the safe reading:
  /// attributing a message to the customer that was not theirs is the worse mistake.
  unknown,
}

/// The customer, as the desk needs them.
///
/// **Four fields, and the phone is the reason this exists.** Whoever is answering «أين طلبيتي؟»
/// reaches for the phone next; making them leave the thread to find the number is the difference
/// between a ticket answered now and one answered later.
@freezed
abstract class TicketCustomer with _$TicketCustomer {
  const factory TicketCustomer({
    required int id,
    String? code,
    String? name,
    String? phone,
  }) = _TicketCustomer;

  factory TicketCustomer.fromJson(Map<String, dynamic> json) =>
      _$TicketCustomerFromJson(json);
}

/// The order a thread is about, named rather than as a bare id.
@freezed
abstract class TicketOrderRef with _$TicketOrderRef {
  const factory TicketOrderRef({required int id, required String code}) = _TicketOrderRef;

  factory TicketOrderRef.fromJson(Map<String, dynamic> json) =>
      _$TicketOrderRefFromJson(json);
}

/// Whose desk a ticket sits on.
@freezed
abstract class TicketAssignee with _$TicketAssignee {
  const factory TicketAssignee({required int id, String? name}) = _TicketAssignee;

  factory TicketAssignee.fromJson(Map<String, dynamic> json) =>
      _$TicketAssigneeFromJson(json);
}

/// نوعُ الملف المرفق، كما قرّره الخادم من بايتاته لا من امتداده.
enum AttachmentKind {
  @JsonValue('image')
  image,
  @JsonValue('pdf')
  pdf,

  /// نوعٌ أضافه الخادم بعد هذا الإصدار — يُعرض ملفاً يُفتح بما في الهاتف، ولا يُسقط الخيط.
  unknown,
}

/// ملفٌ أُرفق برسالة: صورةٌ أو PDF.
///
/// **[url] موقّعٌ وينتهي بعد ساعة**، ويُبنى من جديد مع كل قراءة — فالصورةُ تُخبَّأ برقم الرسالة
/// لا برابطها، وإلا صار كلُّ فتحٍ للخيط تنزيلاً جديداً لصورةٍ لم تتغيّر.
@freezed
abstract class TicketAttachment with _$TicketAttachment {
  const factory TicketAttachment({
    @JsonKey(unknownEnumValue: AttachmentKind.unknown)
    @Default(AttachmentKind.unknown)
    AttachmentKind kind,

    /// «صورة» أو «PDF» — عربيةُ الخادم، فنوعٌ جديد يظهر بلا إصدار.
    @JsonKey(name: 'kind_label') String? kindLabel,

    /// اسمُ الملف كما سمّاه مرسلُه، للعرض وحده.
    String? name,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,
    String? url,
  }) = _TicketAttachment;

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      _$TicketAttachmentFromJson(json);
}

/// One line of a thread.
@freezed
abstract class TicketMessage with _$TicketMessage {
  const factory TicketMessage({
    required int id,
    @JsonKey(unknownEnumValue: MessageAuthor.unknown)
    @Default(MessageAuthor.unknown)
    MessageAuthor from,

    /// **Named on this side, and null on the customer's.** «من ردّ عليه؟» is a question the shop
    /// is entitled to ask of itself; the customer app is sent `me` or `support` and no name,
    /// because a name there makes one person the target of a complaint about a decision the
    /// business made.
    @JsonKey(name: 'author_name') String? authorName,

    /// **فارغٌ حين تكون الرسالةُ ملفاً بلا تعليق** — والخادم يضمن ألّا يجتمع الفراغان.
    String? body,

    TicketAttachment? attachment,

    /// ما ولّده التطبيقُ المرسِل قبل الإرسال؛ الرمزُ نفسه مرتين في التذكرة نفسها رسالةٌ واحدة.
    @JsonKey(name: 'client_token') String? clientToken,

    @JsonKey(name: 'sent_at') DateTime? sentAt,
  }) = _TicketMessage;

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);
}

/// A support thread, as the desk sees it.
///
/// **Wider than the customer's version of the same row** — the assignee, the customer's phone
/// and the author of every reply are all here and none of them cross to the app. They are how
/// the shop organises itself.
@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required int id,
    required String subject,

    @JsonKey(unknownEnumValue: TicketStatus.unknown)
    @Default(TicketStatus.unknown)
    TicketStatus status,

    /// **Always drawn instead of translating [status] here.** The Arabic travels with the value,
    /// so a status added to the business appears without an app release.
    @JsonKey(name: 'status_label') required String statusLabel,

    TicketCustomer? customer,
    TicketOrderRef? order,

    @JsonKey(name: 'assigned_to') int? assignedTo,
    TicketAssignee? assignee,

    /// The **desk's** unread count — the customer's messages this side has not read. Derived
    /// from a read cursor on every request rather than stored, so it cannot drift.
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,

    /// رقمُ آخر رسالةٍ رآها العميل: ردُّ المحل مقروءٌ (✓✓) إن كان رقمه لا يتجاوزه.
    @JsonKey(name: 'customer_read_up_to') int? customerReadUpTo,

    /// Empty on the list endpoint, which does not load them; full on the thread endpoint.
    @Default(<TicketMessage>[]) List<TicketMessage> messages,

    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}
