import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';

/// مسارُ ملفِّ الرسالة إن كان نُزّل إلى هذا الهاتف من قبل، وإلا `null`.
class FindAttachmentOnPhone {
  const FindAttachmentOnPhone(this._store);

  final AttachmentStore _store;

  Future<String?> call(TicketMessage message) =>
      _store.localPath(key: attachmentKeyOf(message), fileName: attachmentNameOf(message));
}

/// هويّةُ ملفِّ الرسالة على الهاتف: رقمها، لا الرابط الموقَّع الذي يتغيّر مع كل قراءة.
String attachmentKeyOf(TicketMessage message) => 'message-${message.id}';

/// الاسم الذي يُحفظ به — ما سمّاه مرسله، وهو ما يظهر في عارض الهاتف وورقة المشاركة.
String attachmentNameOf(TicketMessage message) =>
    message.attachment?.name ??
    (message.attachment?.kind == AttachmentKind.image
        ? 'image-${message.id}.jpg'
        : 'file-${message.id}.pdf');
