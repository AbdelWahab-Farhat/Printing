import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_ticket_thread.freezed.dart';
part 'design_ticket_thread.g.dart';

/// ما يحتاجه شريطُ المحادثة من التذكرة: الكودُ والحالة، والعنوانُ واسمُ العميل تحته، والطرفان.
@freezed
abstract class DesignThreadTicket with _$DesignThreadTicket {
  const factory DesignThreadTicket({
    required int id,
    required String code,
    @Default('') String title,
    @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)
    @Default(DesignTicketStatus.unknown)
    DesignTicketStatus status,
    @JsonKey(name: 'status_label') @Default('') String statusLabel,
    @JsonKey(name: 'is_open') @Default(true) bool isOpen,
    @JsonKey(name: 'customer_name') String? customerName,
    ChatPerson? requester,

    /// مَن يعمل عليها فعلاً — مَن قبلها، أو مَن أُسندت إليه قبل القبول.
    ChatPerson? designer,
  }) = _DesignThreadTicket;

  factory DesignThreadTicket.fromJson(Map<String, dynamic> json) =>
      _$DesignThreadTicketFromJson(json);
}

/// مؤشّرا القراءة كما هما — لمن لا «طرف آخر» عنده: البثُّ، ومَن يقرأ وليس طرفاً.
@freezed
abstract class DesignThreadReadUpTo with _$DesignThreadReadUpTo {
  const factory DesignThreadReadUpTo({int? requester, int? designer}) = _DesignThreadReadUpTo;

  factory DesignThreadReadUpTo.fromJson(Map<String, dynamic> json) =>
      _$DesignThreadReadUpToFromJson(json);
}

/// محادثةُ تذكرة تصميم، كما يراها قارئٌ بعينه — على محرّك التذاكر الداخلية (DESIGN-TICKET-CHAT).
///
/// **الرسائلُ [ChatMessage] نفسها** التي في التذاكر الداخلية، والخادمُ يرسلها بالشكل نفسه.
@freezed
abstract class DesignTicketThread with _$DesignTicketThread {
  const factory DesignTicketThread({
    required DesignThreadTicket ticket,
    @Default(<ChatMessage>[]) List<ChatMessage> messages,

    /// الطالبُ أو المصمّم. مَن سواهما يقرأ ويكتب، ولا ✓✓ له ولا عليه.
    @JsonKey(name: 'is_party') @Default(false) bool isParty,
    @JsonKey(name: 'can_reply') @Default(false) bool canReply,

    /// لماذا لا صندوق — «اعتُمد التصميم وأُغلقت المحادثة». `null` ما دامت مفتوحة.
    @JsonKey(name: 'closed_note') String? closedNote,
    @JsonKey(name: 'read_up_to') DesignThreadReadUpTo? readUpTo,

    /// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
    @JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo,
  }) = _DesignTicketThread;

  const DesignTicketThread._();

  factory DesignTicketThread.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketThreadFromJson(json);

  /// إلى أين قرأ الطرفُ الآخر عند [me] — من الحقل المحسوب حين يعرف الخادمُ القارئ، ومن
  /// المؤشّرين حين لا يعرفه (البثّ).
  int? readByOtherSideUpTo(int? me) {
    if (counterpartReadUpTo != null) return counterpartReadUpTo;

    return otherSideCursor(readUpTo, me);
  }

  /// مؤشّرُ الطرف الآخر عند [me] من [cursors] — ما يأخذه البثُّ الحيّ، و`null` لمن ليس طرفاً.
  int? otherSideCursor(DesignThreadReadUpTo? cursors, int? me) {
    if (cursors == null || me == null) return null;
    if (ticket.requester?.id == me) return cursors.designer;
    if (ticket.designer?.id == me) return cursors.requester;

    return null;
  }

  /// الطرفُ الآخر عند [me]: المصمّمُ عند الطالب، والطالبُ عند المصمّم — و`null` لمن ليس طرفاً.
  ChatPerson? otherSideOf(int? me) {
    if (me == null) return null;
    if (ticket.requester?.id == me) return ticket.designer;
    if (ticket.designer?.id == me) return ticket.requester;

    return null;
  }
}

/// محادثةٌ تغيّرت، كما تسمعها على قناتها الحيّة (`private-design-tickets.{id}`).
@freezed
abstract class DesignTicketThreadChange with _$DesignTicketThreadChange {
  const factory DesignTicketThreadChange({
    /// `message_posted` · `message_edited` · `message_retracted` · `read`.
    required String change,

    /// المحادثةُ بلا رسائلها ولا قارئ — يُؤخذ منها ما لا يختلف بين القرّاء.
    required DesignTicketThread thread,
    ChatMessage? message,
  }) = _DesignTicketThreadChange;

  factory DesignTicketThreadChange.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketThreadChangeFromJson(json);
}
