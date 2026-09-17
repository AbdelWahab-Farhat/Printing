import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

/// Where a ticket has got to.
///
/// Three, and the middle one earns its place: «مفتوحة» and «مغلقة» alone would make an
/// unanswered question and one somebody is actively working on look identical. «قيد المعالجة»
/// means a human has it.
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

/// Who said it.
///
/// **`me` or `support`, never a colleague's name.** Which member of staff answered is the shop's
/// internal arrangement, and naming them would make an individual the target of a complaint
/// about a decision the business made. The server decides this and sends it decided.
enum MessageAuthor {
  @JsonValue('me')
  me,
  @JsonValue('support')
  support,

  unknown,
}

/// One thing somebody said in a thread.
@freezed
abstract class TicketMessage with _$TicketMessage {
  const factory TicketMessage({
    required int id,
    @JsonKey(unknownEnumValue: MessageAuthor.unknown)
    @Default(MessageAuthor.unknown)
    MessageAuthor from,
    required String body,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
  }) = _TicketMessage;

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);
}

extension TicketMessageX on TicketMessage {
  bool get isMine => from == MessageAuthor.me;
}

/// The order a ticket is about, when it is about one.
@freezed
abstract class TicketOrderRef with _$TicketOrderRef {
  const factory TicketOrderRef({required int id, required String code}) = _TicketOrderRef;

  factory TicketOrderRef.fromJson(Map<String, dynamic> json) =>
      _$TicketOrderRefFromJson(json);
}

/// One conversation with the shop.
///
/// **Neither the assignee nor the read cursors arrive.** Whose desk a ticket sits on is how the
/// shop organises itself, and «قرأها الموظف ولم يرد» is a stick rather than information. What
/// does arrive is [unreadCount] — derived on the server from a read cursor, never a stored
/// counter, so it cannot drift.
@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required int id,
    required String subject,
    @JsonKey(unknownEnumValue: TicketStatus.unknown)
    @Default(TicketStatus.unknown)
    TicketStatus status,

    /// Drawn instead of translating [status] here, so a status added to the business appears
    /// correctly without an app release.
    @JsonKey(name: 'status_label') required String statusLabel,

    @JsonKey(name: 'is_open') @Default(true) bool isOpen,

    TicketOrderRef? order,

    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,

    /// Present on the thread endpoint, empty in the list — the list draws a subject and a badge.
    @Default(<TicketMessage>[]) List<TicketMessage> messages,

    /// How long the thread is, and the last thing anybody said in it.
    ///
    /// **Both come from the list endpoint only**, where [messages] is empty — the thread
    /// endpoint sends the messages themselves and these would be a second way to say the same
    /// thing. So a card that came back from the thread screen has no preview, and the card
    /// keeps the one it was drawn with rather than blanking.
    @JsonKey(name: 'messages_count') int? messagesCount,
    String? preview,

    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}
