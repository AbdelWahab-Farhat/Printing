import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';

/// ما يفعله الموظف بالتذاكر بينه وبين زملائه — INTERNAL-TICKETS-DESIGN §٥.
abstract interface class InternalTicketsRepository {
  Future<Either<Failure, Paginated<InternalTicket>>> tickets({
    required InternalTicketQuery query,
    String? search,
    int page,
  });

  /// بطاقةُ الرئيسية.
  Future<Either<Failure, InternalTicketsHome>> home();

  Future<Either<Failure, List<Colleague>>> colleagues();

  Future<Either<Failure, List<InternalCategory>>> categories();

  /// يفتح تذكرةً، و«التفاصيل» وحتى أربع صور أوّلُ رسائلها.
  Future<Either<Failure, InternalTicket>> open(
    InternalTicketDraft draft, {
    List<PickedFile> images,
  });

  /// المحادثةُ كاملة. **فتحُها يعلّمها مقروءة** على الخادم — فلا تُجلب مسبقاً.
  Future<Either<Failure, InternalTicket>> ticket(int id);

  /// يرسل، ويُرجع التذكرةَ بالرسالة فيها.
  Future<Either<Failure, InternalTicket>> send(int id, OutgoingChatMessage message);

  /// يعدّل نصَّ رسالتي — خلال عشرين دقيقة.
  Future<Either<Failure, ChatMessage>> edit(int id, int messageId, String body);

  /// يسحب رسالتي: تبقى مكانها وتقول «تم حذف هذه الرسالة».
  Future<Either<Failure, ChatMessage>> retract(int id, int messageId);

  /// لشاشةٍ مفتوحة وصلتها رسالةٌ حيّة: حتى [upToMessageId].
  Future<Either<Failure, Unit>> markRead(int id, {int? upToMessageId});

  Future<Either<Failure, InternalTicket>> close(int id);

  /// صاحبُها يسلّمها لموظفٍ آخر يحلّ محلّه.
  Future<Either<Failure, InternalTicket>> transfer(int id, {required int newOwnerId});

  /// كلُّ ما يتغيّر في محادثةٍ واحدة، ساعةَ يتغيّر. لا يطلق شيئاً حين لا يكون البثّ مُعدّاً.
  Stream<InternalTicketChange> watchTicket(int id);

  /// إشارةٌ بأن تذكرةً أنا طرفٌ فيها تغيّرت — رقمُها وحده.
  Stream<int> watchMine(int userId);

  /// عاد الاتصال الحيّ بعد انقطاع — ما تغيّر فيه فات.
  Stream<void> get liveResumed;
}
