import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';

/// What the desk can do about the threads customers start.
///
/// **No `open`.** A ticket is a customer beginning a conversation; the shop opening one on
/// somebody's behalf would be a thread the customer never asked for and cannot recognise. The
/// customer app's own endpoint is the only door that creates one — see `SupportTicketController`,
/// which has no `store` either.
abstract interface class SupportRepository {
  /// One page of the queue, most recently active first.
  ///
  /// [status] narrows to a state and [assignedTo] to one person's desk. Both null is the whole
  /// queue, which is what the shift lead reads.
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({
    int page,
    TicketStatus? status,
    int? assignedTo,
  });

  /// The whole thread.
  ///
  /// **Reading it marks the desk's side read**, server-side. That is a GET with a side effect
  /// and it is deliberate: the unread badge should clear because somebody looked, not because
  /// they remembered to press something. It means this call is not safe to make speculatively —
  /// prefetching a thread would mark it read without anybody seeing it.
  Future<Either<Failure, SupportTicket>> ticket(int id);

  /// Answers, and returns the thread with the reply in it.
  ///
  /// The author is never sent: the server stamps the signed-in user, which is what makes it
  /// impossible to sign a colleague's name to a sentence. Puts the ticket on «قيد المعالجة».
  ///
  /// [attachment] صورةٌ أو PDF، و[body] حينها تعليقٌ اختياريّ — والخادم يرفض الفراغين معاً.
  Future<Either<Failure, SupportTicket>> reply(
    int id, {
    String? body,
    PickedFile? attachment,
  });

  /// Puts a ticket on somebody's desk, or [userId] null to put it back in the unassigned queue.
  Future<Either<Failure, SupportTicket>> assign(int id, {required int? userId});

  /// Ends the conversation.
  ///
  /// **Idempotent on the server** — two people pressing it is not a failure, and the second
  /// press must not overwrite the first one's name.
  Future<Either<Failure, SupportTicket>> close(int id);

  /// يعيد فتحَ تذكرةٍ أغلقها المكتب، عن قصد — الموظف لا يكتب في المغلقة إلا بعدها. تعود
  /// «قيد المعالجة». وإعادةُ فتح المفتوحة لا تُعدّ خطأ.
  Future<Either<Failure, SupportTicket>> reopen(int id);

  /// كلُّ تذكرةٍ تتغيّر في المكتب، ساعةَ تتغيّر: رسالة، إسناد، إغلاق، إعادة فتح، قراءة.
  ///
  /// **لا يطلق شيئاً حين لا يكون البثّ مُعدّاً**، والشاشات تعمل بالسحب كما كانت. ولا يحمل
  /// خطأً قط: الاتصال الذي سقط يُعاد تحته، ويُقال ذلك في [liveResumed].
  Stream<TicketChange> watchChanges();

  /// عاد الاتصال الحيّ بعد انقطاع — ما تغيّر في الانقطاع فات، فمن يرسم تذكرةً يعيد قراءتها.
  Stream<void> get liveResumed;
}
