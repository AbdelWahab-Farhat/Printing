import 'package:dayaa/core/files/picked_file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// ما في الرسالة غير الكلام: صورة، أو رسالة صوتية.
enum ChatAttachmentKind {
  @JsonValue('image')
  image,
  @JsonValue('voice')
  voice,

  unknown,
}

/// موظفٌ باسمه — طرفٌ في المحادثة، أو كاتبُ رسالة.
@freezed
abstract class ChatPerson with _$ChatPerson {
  const factory ChatPerson({required int id, required String name}) = _ChatPerson;

  factory ChatPerson.fromJson(Map<String, dynamic> json) => _$ChatPersonFromJson(json);
}

/// صورةٌ أو رسالةٌ صوتية.
///
/// **[id] مفتاحُ حفظها على الهاتف لا [url]**: الرابطُ موقّعٌ ويتغيّر مع كل قراءة، والملفُّ خلفه
/// لا يتغيّر — فينزل الصوت مرّةً واحدة.
@freezed
abstract class ChatAttachment with _$ChatAttachment {
  const factory ChatAttachment({
    required int id,
    @JsonKey(unknownEnumValue: ChatAttachmentKind.unknown)
    @Default(ChatAttachmentKind.unknown)
    ChatAttachmentKind kind,
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
  }) = _ChatAttachment;

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => _$ChatAttachmentFromJson(json);
}

/// الرسالةُ المقتبَسة في سطرٍ واحد.
@freezed
abstract class ChatQuote with _$ChatQuote {
  const factory ChatQuote({
    required int id,
    @JsonKey(name: 'author_name') String? authorName,
    @Default('') String preview,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _ChatQuote;

  factory ChatQuote.fromJson(Map<String, dynamic> json) => _$ChatQuoteFromJson(json);
}

/// رسالةٌ في محادثةٍ بين الموظفين — تذكرةٌ داخلية أو تذكرةُ تصميم.
///
/// **شكلٌ واحد على الشبكة للمحادثتين**: الخادمُ يرسل رسالة تذكرة التصميم بشكل رسالة التذكرة
/// الداخلية حرفاً بحرف، فتُقرأ بهذا النموذج وتُرسم بقطع `core/chat` نفسها (DESIGN-TICKET-CHAT).
///
/// **الأعلامُ من الخادم** ([canEdit] و[canDelete] و[mutableUntil]). وفي البثّ الحيّ لا قارئ —
/// الأعلامُ `false` و[isMine] `false` دائماً — فالشاشةُ تحسب «رسالتي» من [author] ([isFrom]).
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    @JsonKey(name: 'ticket_id') int? ticketId,
    ChatPerson? author,
    @JsonKey(name: 'is_mine') @Default(false) bool isMine,

    /// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
    String? body,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'is_edited') @Default(false) bool isEdited,
    @JsonKey(name: 'reply_to') ChatQuote? replyTo,
    @Default(<ChatAttachment>[]) List<ChatAttachment> attachments,
    @JsonKey(name: 'client_token') String? clientToken,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
    @JsonKey(name: 'can_edit') @Default(false) bool canEdit,
    @JsonKey(name: 'can_delete') @Default(false) bool canDelete,

    /// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
    @JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,
    @JsonKey(name: 'mutable_until') DateTime? mutableUntil,
  }) = _ChatMessage;

  const ChatMessage._();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  /// رسالتي — من [isMine] حين يعرف الخادمُ القارئ، ومن الكاتب حين لا يعرف (البثّ).
  bool isFrom(int? me) => isMine || (me != null && author?.id == me);

  ChatAttachment? get voice =>
      attachments.where((file) => file.kind == ChatAttachmentKind.voice).firstOrNull;

  ChatAttachment? get image =>
      attachments.where((file) => file.kind == ChatAttachmentKind.image).firstOrNull;

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

/// رسالةٌ صوتية لم تصل — تبقى فوق صندوق الكتابة بزرّين: «أعد الإرسال» و«احذفها».
///
/// **التسجيلُ لا يُرمى لأن الشبكة سقطت**: خمسُ دقائق من الكلام لا يُطلب من أحدٍ أن يقولها ثانيةً.
/// والرمزُ نفسه في الإعادة ([clientToken])، فإن كانت الأولى قد وصلت فعلاً لم تُكتب ثانية.
@freezed
abstract class PendingVoice with _$PendingVoice {
  const factory PendingVoice({
    required String path,
    required int durationSeconds,
    required List<int> waveform,
    required String clientToken,
    int? replyToMessageId,
  }) = _PendingVoice;
}

/// رسالةٌ في طريقها: كلامٌ، أو صورة، أو صوتٌ بمدّته وموجته، وربما اقتباس.
class OutgoingChatMessage {
  const OutgoingChatMessage({
    required this.clientToken,
    this.body,
    this.file,
    this.durationSeconds,
    this.waveform,
    this.replyToMessageId,
  });

  /// يولّده التطبيق قبل الإرسال ويعيده كما هو في الإعادة — فالرمزُ نفسه رسالةٌ واحدة على الخادم.
  final String clientToken;
  final String? body;
  final PickedFile? file;
  final int? durationSeconds;
  final List<int>? waveform;
  final int? replyToMessageId;

  /// الرسالةُ نفسها مقتبِسةً [messageId] — ما يضيفه الـCubit حين يكون في الصندوق اقتباس.
  OutgoingChatMessage quoting(int messageId) => OutgoingChatMessage(
    clientToken: clientToken,
    body: body,
    file: file,
    durationSeconds: durationSeconds,
    waveform: waveform,
    replyToMessageId: messageId,
  );
}
