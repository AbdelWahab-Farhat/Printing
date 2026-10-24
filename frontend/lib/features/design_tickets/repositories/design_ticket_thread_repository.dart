import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';

/// محادثة تذكرة التصميم — على محرّك التذاكر الداخلية (DESIGN-TICKET-CHAT §٥).
///
/// **مستودعٌ وحده لا جزءٌ من [DesignTicketRepository]**، كما كانت الملاحظات: المحادثةُ شأنٌ قائم
/// بنفسه — رسائلُ وبثٌّ حيّ ومؤشّرا قراءة — والتذكرةُ لا تحتاج أن تعرف عنه شيئاً.
abstract interface class DesignTicketThreadRepository {
  /// المحادثةُ كاملة. **فتحُها يعلّمها مقروءة** على الخادم ويطفئ جرسها — فلا تُجلب مسبقاً.
  Future<Either<Failure, DesignTicketThread>> thread(int ticketId);

  /// يرسل، ويُرجع المحادثةَ بالرسالة فيها.
  Future<Either<Failure, DesignTicketThread>> send(int ticketId, OutgoingChatMessage message);

  /// يعدّل نصَّ رسالتي — خلال عشرين دقيقة.
  Future<Either<Failure, ChatMessage>> edit(int ticketId, int messageId, String body);

  /// يسحب رسالتي: تبقى مكانها وتقول «تم حذف هذه الرسالة».
  Future<Either<Failure, ChatMessage>> retract(int ticketId, int messageId);

  /// لشاشةٍ مفتوحة وصلتها رسالةٌ حيّة: حتى [upToMessageId]. ويجيب برقم الجرس الجديد.
  Future<Either<Failure, int>> markRead(int ticketId, {int? upToMessageId});

  /// كلُّ ما يتغيّر في المحادثة، ساعةَ يتغيّر. لا يطلق شيئاً حين لا يكون البثّ مُعدّاً.
  Stream<DesignTicketThreadChange> watch(int ticketId);

  /// عاد الاتصال الحيّ بعد انقطاع — ما تغيّر فيه فات.
  Stream<void> get liveResumed;
}
