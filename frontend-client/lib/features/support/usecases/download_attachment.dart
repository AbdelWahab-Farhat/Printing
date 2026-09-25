import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/usecases/find_attachment_on_phone.dart';

/// ينزّل ملفَّ رسالةٍ إلى الهاتف، ويُرجع مساره.
class DownloadAttachment {
  const DownloadAttachment(this._store);

  final AttachmentStore _store;

  Future<Either<Failure, String>> call(
    TicketMessage message, {
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) async {
    final url = message.attachment?.url;

    if (url == null) {
      return const Left(Failure.unexpected(message: 'لا يوجد رابط لهذا الملف'));
    }

    return _store.download(
      url: url,
      key: attachmentKeyOf(message),
      fileName: attachmentNameOf(message),
      onProgress: onProgress,
      cancel: cancel,
    );
  }
}
