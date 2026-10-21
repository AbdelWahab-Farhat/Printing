import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_ticket.freezed.dart';
part 'internal_ticket.g.dart';

/// أين وصلت تذكرةٌ بين موظفَين. اثنتان فقط، كبريمولا والخادم: تولد «قيد المعالجة»، والإغلاقُ
/// نهائيّ.
///
/// **`unknown` ليس حالةً عند أحد** — هو ما تُفكّ إليه حالةٌ أضافها الخادم بعد هذا الإصدار، فلا
/// تُسقط القائمة. وكلُّ حالةٍ تحمل `@JsonValue` كالحالات في الدعم.
enum InternalTicketStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('closed')
  closed,

  unknown,
}

extension InternalTicketStatusX on InternalTicketStatus {
  bool get isOpen => this == InternalTicketStatus.inProgress;

  /// ما يُرسل فلتراً — والمجهولةُ لا فلتر.
  String? get wire => switch (this) {
    InternalTicketStatus.inProgress => 'in_progress',
    InternalTicketStatus.closed => 'closed',
    InternalTicketStatus.unknown => null,
  };

  /// للرقاقتين وحدهما — التذكرةُ نفسها ترسم `status_label` الذي يأتي معها.
  String get label => switch (this) {
    InternalTicketStatus.inProgress => 'قيد المعالجة',
    InternalTicketStatus.closed => 'مغلقة',
    InternalTicketStatus.unknown => 'غير معروفة',
  };
}

/// «الأولوية»: منخفضة / متوسطة / عالية، والافتراضيّ متوسطة.
enum InternalTicketPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,

  unknown,
}

extension InternalTicketPriorityX on InternalTicketPriority {
  String get wire => switch (this) {
    InternalTicketPriority.low => 'low',
    InternalTicketPriority.high => 'high',
    InternalTicketPriority.medium || InternalTicketPriority.unknown => 'medium',
  };

  String get label => switch (this) {
    InternalTicketPriority.low => 'منخفضة',
    InternalTicketPriority.medium => 'متوسطة',
    InternalTicketPriority.high => 'عالية',
    InternalTicketPriority.unknown => 'غير معروفة',
  };
}

/// ما في الرسالة غير الكلام: صورة، أو رسالة صوتية.
enum InternalAttachmentKind {
  @JsonValue('image')
  image,
  @JsonValue('voice')
  voice,

  unknown,
}

/// موظفٌ باسمه — طرفٌ في التذكرة، أو كاتبُ رسالة.
@freezed
abstract class InternalPerson with _$InternalPerson {
  const factory InternalPerson({required int id, required String name}) = _InternalPerson;

  factory InternalPerson.fromJson(Map<String, dynamic> json) => _$InternalPersonFromJson(json);
}

@freezed
abstract class InternalCustomerRef with _$InternalCustomerRef {
  const factory InternalCustomerRef({required int id, String? code, String? name, String? phone}) =
      _InternalCustomerRef;

  factory InternalCustomerRef.fromJson(Map<String, dynamic> json) =>
      _$InternalCustomerRefFromJson(json);
}

@freezed
abstract class InternalOrderRef with _$InternalOrderRef {
  const factory InternalOrderRef({required int id, required String code}) = _InternalOrderRef;

  factory InternalOrderRef.fromJson(Map<String, dynamic> json) => _$InternalOrderRefFromJson(json);
}

/// «نوع المشكلة».
@freezed
abstract class InternalCategory with _$InternalCategory {
  const factory InternalCategory({required int id, required String name}) = _InternalCategory;

  factory InternalCategory.fromJson(Map<String, dynamic> json) => _$InternalCategoryFromJson(json);
}

/// صورةٌ أو رسالةٌ صوتية.
///
/// **[id] مفتاحُ حفظها على الهاتف لا [url]**: الرابطُ موقّعٌ ويتغيّر مع كل قراءة، والملفُّ خلفه
/// لا يتغيّر — فينزل الصوت مرّةً واحدة.
@freezed
abstract class InternalAttachment with _$InternalAttachment {
  const factory InternalAttachment({
    required int id,
    @JsonKey(unknownEnumValue: InternalAttachmentKind.unknown)
    @Default(InternalAttachmentKind.unknown)
    InternalAttachmentKind kind,
    String? name,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    /// للصوت: كما قاسها الهاتف المرسِل، للعرض.
    @JsonKey(name: 'duration_seconds') int? durationSeconds,

    /// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
    List<int>? waveform,
    String? url,
  }) = _InternalAttachment;

  factory InternalAttachment.fromJson(Map<String, dynamic> json) =>
      _$InternalAttachmentFromJson(json);
}

/// الرسالةُ المقتبَسة في سطرٍ واحد.
@freezed
abstract class InternalQuote with _$InternalQuote {
  const factory InternalQuote({
    required int id,
    @JsonKey(name: 'author_name') String? authorName,
    @Default('') String preview,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _InternalQuote;

  factory InternalQuote.fromJson(Map<String, dynamic> json) => _$InternalQuoteFromJson(json);
}

/// رسالةٌ في تذكرةٍ داخلية.
///
/// **الأعلامُ من الخادم** ([canEdit] و[canDelete] و[mutableUntil])، كبريمولا. وفي البثّ الحيّ لا
/// قارئ — الأعلامُ `false` و[isMine] `false` دائماً — فالشاشةُ تحسب «رسالتي» من [author] والمهلةَ من
/// [mutableUntil]؛ انظر `InternalMessageX`.
@freezed
abstract class InternalMessage with _$InternalMessage {
  const factory InternalMessage({
    required int id,
    @JsonKey(name: 'ticket_id') int? ticketId,
    InternalPerson? author,
    @JsonKey(name: 'is_mine') @Default(false) bool isMine,

    /// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
    String? body,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'is_edited') @Default(false) bool isEdited,
    @JsonKey(name: 'reply_to') InternalQuote? replyTo,
    @Default(<InternalAttachment>[]) List<InternalAttachment> attachments,
    @JsonKey(name: 'client_token') String? clientToken,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
    @JsonKey(name: 'can_edit') @Default(false) bool canEdit,
    @JsonKey(name: 'can_delete') @Default(false) bool canDelete,

    /// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
    @JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,
    @JsonKey(name: 'mutable_until') DateTime? mutableUntil,
  }) = _InternalMessage;

  const InternalMessage._();

  factory InternalMessage.fromJson(Map<String, dynamic> json) => _$InternalMessageFromJson(json);

  /// رسالتي — من [isMine] حين يعرف الخادمُ القارئ، ومن الكاتب حين لا يعرف (البثّ).
  bool isFrom(int? me) => isMine || (me != null && author?.id == me);

  InternalAttachment? get voice =>
      attachments.where((file) => file.kind == InternalAttachmentKind.voice).firstOrNull;

  InternalAttachment? get image =>
      attachments.where((file) => file.kind == InternalAttachmentKind.image).firstOrNull;

  /// سطرٌ واحد عنها — للاقتباس فوق صندوق الكتابة.
  String get preview {
    if (isDeleted) return 'تم حذف هذه الرسالة';

    final text = body?.trim() ?? '';
    if (text.isNotEmpty) return text;
    if (voice != null) return '🎤 رسالة صوتية';
    if (image != null) return 'صورة';

    return '';
  }
}

/// آخرُ كلامٍ حيٍّ في التذكرة — معاينةُ الصفّ.
@freezed
abstract class InternalLastMessage with _$InternalLastMessage {
  const factory InternalLastMessage({
    required int id,
    @JsonKey(name: 'author_id') int? authorId,
    @JsonKey(name: 'author_name') String? authorName,
    @Default('') String preview,

    /// `text` أو `image` أو `voice` — أيقونةٌ قبل المعاينة.
    @Default('text') String kind,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
  }) = _InternalLastMessage;

  factory InternalLastMessage.fromJson(Map<String, dynamic> json) =>
      _$InternalLastMessageFromJson(json);
}

/// مؤشّرا القراءة كما هما — لمن لا «طرف آخر» عنده: البثُّ، والمدير.
@freezed
abstract class InternalReadUpTo with _$InternalReadUpTo {
  const factory InternalReadUpTo({int? opener, int? assignee}) = _InternalReadUpTo;

  factory InternalReadUpTo.fromJson(Map<String, dynamic> json) => _$InternalReadUpToFromJson(json);
}

/// تذكرةٌ بين موظفَين، كما يراها قارئٌ بعينه.
@freezed
abstract class InternalTicket with _$InternalTicket {
  const factory InternalTicket({
    required int id,
    required String code,
    required String title,
    @JsonKey(unknownEnumValue: InternalTicketStatus.unknown)
    @Default(InternalTicketStatus.unknown)
    InternalTicketStatus status,
    @JsonKey(name: 'status_label') @Default('') String statusLabel,
    @JsonKey(unknownEnumValue: InternalTicketPriority.unknown)
    @Default(InternalTicketPriority.medium)
    InternalTicketPriority priority,
    @JsonKey(name: 'priority_label') @Default('') String priorityLabel,
    InternalCategory? category,
    InternalPerson? opener,
    InternalPerson? assignee,

    /// الطرفُ الآخر عند هذا القارئ. `null` للمدير الذي ليس طرفاً — وفي البثّ.
    InternalPerson? counterpart,
    @JsonKey(name: 'i_opened_it') @Default(false) bool iOpenedIt,
    @JsonKey(name: 'is_party') @Default(false) bool isParty,
    InternalCustomerRef? customer,
    InternalOrderRef? order,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,

    /// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
    @JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo,
    @JsonKey(name: 'read_up_to') InternalReadUpTo? readUpTo,
    @JsonKey(name: 'awaiting_my_reply') @Default(false) bool awaitingMyReply,
    @JsonKey(name: 'last_message') InternalLastMessage? lastMessage,

    /// فارغةٌ في القائمة، كاملةٌ في المحادثة.
    @Default(<InternalMessage>[]) List<InternalMessage> messages,
    @JsonKey(name: 'can_reply') @Default(false) bool canReply,
    @JsonKey(name: 'can_close') @Default(false) bool canClose,
    @JsonKey(name: 'can_transfer') @Default(false) bool canTransfer,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
    @JsonKey(name: 'closed_by') InternalPerson? closedBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _InternalTicket;

  const InternalTicket._();

  factory InternalTicket.fromJson(Map<String, dynamic> json) => _$InternalTicketFromJson(json);

  /// إلى أين قرأ الطرفُ الآخر عند [me] — من الحقل المحسوب حين يعرف الخادمُ القارئ، ومن
  /// المؤشّرين حين لا يعرفه (البثّ).
  int? readByOtherSideUpTo(int? me) {
    if (counterpartReadUpTo != null) return counterpartReadUpTo;
    if (me == null) return null;
    if (opener?.id == me) return readUpTo?.assignee;
    if (assignee?.id == me) return readUpTo?.opener;

    return null;
  }

  /// الطرفُ الآخر عند [me]، أو `null` لمن ليس طرفاً.
  InternalPerson? otherSideOf(int? me) {
    if (counterpart != null) return counterpart;
    if (me == null) return null;
    if (opener?.id == me) return assignee;
    if (assignee?.id == me) return opener;

    return null;
  }
}

/// بطاقةُ الرئيسية: ما ينتظر ردّي، وأرقامُ ما على مكتبي.
@freezed
abstract class InternalTicketsHome with _$InternalTicketsHome {
  const factory InternalTicketsHome({
    @Default(<InternalTicket>[]) List<InternalTicket> tickets,
    @JsonKey(name: 'awaiting_my_reply') @Default(0) int awaitingMyReply,
    @JsonKey(name: 'has_more') @Default(false) bool hasMore,
    @JsonKey(name: 'total_open') @Default(0) int totalOpen,
    @JsonKey(name: 'unread_tickets') @Default(0) int unreadTickets,
  }) = _InternalTicketsHome;

  factory InternalTicketsHome.fromJson(Map<String, dynamic> json) =>
      _$InternalTicketsHomeFromJson(json);
}

/// زميلٌ في ورقة «مع مَن؟».
@freezed
abstract class Colleague with _$Colleague {
  const factory Colleague({
    required int id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
    @Default(<String>[]) List<String> roles,
    @JsonKey(name: 'open_tickets_with_me') @Default(0) int openTicketsWithMe,
  }) = _Colleague;

  factory Colleague.fromJson(Map<String, dynamic> json) => _$ColleagueFromJson(json);
}

/// تذكرةٌ تغيّرت، كما تسمعها محادثتها على قناتها الحيّة (`private-internal-tickets.{id}`).
@freezed
abstract class InternalTicketChange with _$InternalTicketChange {
  const factory InternalTicketChange({
    /// `message_posted` · `message_edited` · `message_retracted` · `read` · `closed` · `transferred`.
    required String change,
    required InternalTicket ticket,
    InternalMessage? message,
  }) = _InternalTicketChange;

  factory InternalTicketChange.fromJson(Map<String, dynamic> json) =>
      _$InternalTicketChangeFromJson(json);
}
