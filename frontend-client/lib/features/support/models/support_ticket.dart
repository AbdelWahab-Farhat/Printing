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

/// أيُّ ملفٍّ في الرسالة — **قرّره الخادم من البايتات**، وهو ما يقرّر هل تُرسم الصورة داخل
/// المحادثة أم يُسلَّم الملف لعارض الهاتف.
enum AttachmentKind {
  @JsonValue('image')
  image,
  @JsonValue('pdf')
  pdf,

  /// صنفٌ أُضيف إلى الـAPI بعد هذا البناء — يُرسم ملفاً عاماً ولا يُكسر به شيء.
  unknown,
}

/// ملفُّ رسالةٍ: صورةٌ أو PDF.
///
/// **الرابط يُبنى عند كل قراءة ولا يُحفظ.** القرص خاص، فالرابط موقَّعٌ ينتهي؛ ما يبقى في هذا
/// التطبيق يُحفظ بمفتاح الرسالة لا بالرابط — الرابط يتغيّر، والملف خلفه لا يتغيّر أبداً.
@freezed
abstract class TicketAttachment with _$TicketAttachment {
  const factory TicketAttachment({
    @JsonKey(unknownEnumValue: AttachmentKind.unknown)
    @Default(AttachmentKind.unknown)
    AttachmentKind kind,

    /// «صورة» أو «PDF» — كلمة الخادم، فلا جدول ترجمةٍ هنا.
    @JsonKey(name: 'kind_label') String? kindLabel,

    /// ما سمّاه مرسله. للعرض وحده.
    String? name,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'size_bytes') int? sizeBytes,

    /// للصور وحدها: يحجز مكان الصورة بنسبتها قبل أن تصل، فلا تقفز المحادثة تحت الإصبع.
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    String? url,
  }) = _TicketAttachment;

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      _$TicketAttachmentFromJson(json);
}

extension TicketAttachmentX on TicketAttachment {
  bool get isImage => kind == AttachmentKind.image;

  /// عرضٌ على ارتفاع، أو `null` حين لا أبعاد — PDF، أو صورةٌ لم تُقرأ أبعادها.
  double? get aspectRatio {
    final width = widthPx;
    final height = heightPx;

    if (width == null || height == null || width <= 0 || height <= 0) return null;

    return width / height;
  }

  /// «PDF · 1.2 م.ب» — السطر تحت اسم الملف، مقرَّباً كما يقرّب مدير الملفات.
  String get metaLine {
    final bytes = sizeBytes;
    final size = switch (bytes) {
      null || <= 0 => null,
      < 1024 * 1024 => '${(bytes / 1024).round()} ك.ب',
      _ => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب',
    };

    return [?kindLabel, ?size].join(' · ');
  }
}

/// One thing somebody said in a thread.
@freezed
abstract class TicketMessage with _$TicketMessage {
  const factory TicketMessage({
    required int id,
    @JsonKey(unknownEnumValue: MessageAuthor.unknown)
    @Default(MessageAuthor.unknown)
    MessageAuthor from,

    /// **فارغٌ لرسالةٍ هي ملفٌّ بلا تعليق** — يصل `null` ويُقرأ هنا نصاً فارغاً، كي لا يسأل كلُّ
    /// من يرسم رسالةً «هل لها نص؟» بنوعٍ قد يكون `null`.
    @Default('') String body,

    TicketAttachment? attachment,

    /// الرمز الذي ولّده هذا التطبيق قبل الإرسال. به تُعرف الفقاعة المعلّقة التي صارت هذه
    /// الرسالة، وبه يُعيد الخادم الرسالة نفسها لا نسخةً ثانية حين يُعاد الإرسال.
    @JsonKey(name: 'client_token') String? clientToken,

    @JsonKey(name: 'sent_at') DateTime? sentAt,
  }) = _TicketMessage;

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);
}

extension TicketMessageX on TicketMessage {
  bool get isMine => from == MessageAuthor.me;

  bool get hasText => body.trim().isNotEmpty;

  /// ما يُقال عن الرسالة في سطرٍ واحد: نصُّها، أو «صورة»، أو اسمُ ملف الـPDF.
  ///
  /// **القاعدة نفسها التي يطبّقها الخادم على `preview`** (`TicketMessage::previewText()`)، لأن
  /// البثّ الحيّ يحمل الرسالة بلا سطر معاينة، والقائمة تأخذه منها.
  String get previewText {
    if (hasText) return body;

    return switch (attachment) {
      TicketAttachment(kind: AttachmentKind.image) => 'صورة',
      TicketAttachment(:final name?) => name,
      TicketAttachment() => 'ملف',
      null => '',
    };
  }
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
/// **The assignee does not arrive, and neither does *when* anybody read.** Whose desk a ticket
/// sits on is how the shop organises itself. What does arrive is [unreadCount] — derived on the
/// server from a read cursor, never a stored counter, so it cannot drift — and, since
/// 2026-09-25, [supportReadUpTo]: صاحب المحل طلب علامة القراءة ✓✓ كما في تطبيقات المحادثة،
/// فيصل الحدّ وحده، لا ساعة القراءة ولا اسم من قرأ.
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

    /// **علامة القراءة**: رقمُ آخر رسالةٍ رآها المحل، أو `null` إن لم يفتح الخيط بعد. رسالتي
    /// مقروءةٌ (✓✓) إن كان رقمها لا يتجاوزه — انظر [SupportTicketX.isReadBySupport]. الحدّ وحده
    /// يصل: متى قرأها ومن قرأها لا يغادران الخادم.
    @JsonKey(name: 'support_read_up_to') int? supportReadUpTo,

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

extension SupportTicketX on SupportTicket {
  /// هل رأى المحلُّ رسالتي هذه؟ رسائل الدعم لا تُسأل عنها — لا علامة عليها.
  bool isReadBySupport(TicketMessage message) {
    final readUpTo = supportReadUpTo;

    return message.isMine && readUpTo != null && message.id <= readUpTo;
  }
}
