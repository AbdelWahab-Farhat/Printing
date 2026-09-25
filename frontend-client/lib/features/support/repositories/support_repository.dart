import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';

/// Reaching a person.
abstract interface class SupportRepository {
  /// The customer's own threads, most recently active first.
  ///
  /// [openOnly] null means everything; `true` the live ones, `false` the closed.
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({int page, bool? openOnly});

  /// One thread, oldest message first.
  ///
  /// **Reading it marks it read** — the server does that on this call, which is why there is no
  /// «mark as read» endpoint for this app to forget on the screen where it matters.
  Future<Either<Failure, SupportTicket>> ticket(int id);

  /// Starts a conversation. [orderId] must be one of the customer's own orders — the server
  /// resolves it through them, so somebody else's id is a 404 rather than a ticket quietly
  /// attached to a stranger's order.
  Future<Either<Failure, SupportTicket>> open({
    required String subject,
    required String body,
    int? orderId,
  });

  /// Replies — كلاماً، أو ملفاً ([file]، صورة أو PDF)، أو كليهما.
  ///
  /// **A reply to a closed ticket reopens it**, and that is the server's decision, not this
  /// app's: a thread somebody is still writing into is closed on paper and open in fact, and
  /// that gap is where a customer gets ignored.
  ///
  /// [clientToken] يولّده التطبيق قبل الإرسال، فالإعادة بالرمز نفسه تُرجع الرسالة نفسها لا نسخةً
  /// ثانية. [onProgress] من ٠ إلى ١ أثناء رفع الملف، و[cancel] يوقفه.
  Future<Either<Failure, SupportTicket>> reply({
    required int id,
    String body = '',
    PickedFile? file,
    String? clientToken,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  });

  /// كلُّ تغيّرٍ في تذاكري، ساعةَ يقع: ردٌّ من المحل، إغلاق، إعادة فتح، قراءة.
  ///
  /// **قناتي تُعرف من رقمي، ورقمي من الخادم** (`auth/me`) مرةً لكل رمز دخول. ولا يطلق شيئاً حين
  /// لا يكون البثّ مُعدّاً أو لا جلسة — والشاشات تعمل بالسحب كما كانت. ولا يحمل خطأً قط.
  Stream<TicketChange> watchChanges();

  /// عاد الاتصال الحيّ بعد انقطاع — ما تغيّر في الانقطاع فات، فمن يرسم تذكرةً يعيد قراءتها.
  Stream<void> get liveResumed;
}
