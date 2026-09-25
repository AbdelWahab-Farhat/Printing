import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/usecases/download_attachment.dart';
import 'package:dayaa_client/features/support/usecases/find_attachment_on_phone.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_files_cubit.freezed.dart';
part 'attachment_files_state.dart';

/// آليةُ تنزيل ملفات المحادثة، كما في تيليغرام: سهمٌ، فحلقةٌ تمتلئ يمكن إلغاؤها، فملفٌّ يُفتح.
///
/// **منفصلٌ عن `TicketThreadCubit` عمداً.** الخيط يتبدّل كلّه مع كل ردٍّ وكل حدثٍ حيّ؛ وتنزيلٌ في
/// منتصفه لا يجوز أن يبدأ من الصفر لأن رسالةً جديدة وصلت. ولكلٍّ منهما سببٌ مستقل ليتغيّر.
///
/// **الصور لا تمرّ من هنا لتُرسم** — `CachedNetworkImage` يحمّلها ويحفظها ويُظهر تقدّمها بنفسه.
/// تمرّ من هنا حين تُحفظ أو تُشارَك، لأن ورقة المشاركة تأخذ ملفاً لا صورةً في الذاكرة.
class AttachmentFilesCubit extends Cubit<AttachmentFilesState> {
  AttachmentFilesCubit({
    required FindAttachmentOnPhone find,
    required DownloadAttachment download,
  }) : _find = find,
       _download = download,
       super(const AttachmentFilesState());

  final FindAttachmentOnPhone _find;
  final DownloadAttachment _download;
  final Map<int, TransferCancel> _transfers = {};

  /// يسأل الهاتف أيّ هذه الملفات عنده من قبل — مرّةً لكل رسالة، فلا يُرسم سهمُ تنزيلٍ فوق ملفٍّ
  /// على الهاتف أصلاً.
  Future<void> discover(Iterable<TicketMessage> messages) async {
    for (final message in messages) {
      if (message.attachment == null || state.files.containsKey(message.id)) continue;

      final path = await _find(message);
      if (isClosed) return;

      if (path != null && !state.files.containsKey(message.id)) {
        _set(message.id, AttachmentFile.local(path));
      }
    }
  }

  /// ينزّل الملف، أو يُرجع مساره إن كان هنا. `null` حين فشل أو أُلغي أو كان في الطريق.
  Future<String?> fetch(TicketMessage message) async {
    switch (state.of(message.id)) {
      case AttachmentLocal(:final path):
        return path;
      case AttachmentDownloading():
        return null;
      case AttachmentRemote() || AttachmentDownloadFailed():
        break;
    }

    final cancel = TransferCancel();
    _transfers[message.id] = cancel;
    _set(message.id, const AttachmentFile.downloading());

    var shown = 0.0;
    final result = await _download(
      message,
      cancel: cancel,
      onProgress: (progress) {
        // لا حالةَ جديدة لكل كتلة بايتات: كل نقطتين مئويتين تكفيان لحلقةٍ تُرى تمتلئ.
        if (isClosed || cancel.isCancelled || progress - shown < 0.02) return;

        shown = progress;
        _set(message.id, AttachmentFile.downloading(progress: progress));
      },
    );

    _transfers.remove(message.id);
    if (isClosed) return null;

    // الإلغاء ليس فشلاً: من ألغى يعرف أنه ألغى، فيعود السهم بلا رسالة خطأ.
    if (cancel.isCancelled) {
      _set(message.id, const AttachmentFile.remote());

      return null;
    }

    return result.fold(
      (failure) {
        _set(message.id, AttachmentFile.failed(failure));

        return null;
      },
      (path) {
        _set(message.id, AttachmentFile.local(path));

        return path;
      },
    );
  }

  /// يوقف تنزيلاً جارياً.
  void cancel(int messageId) => _transfers[messageId]?.cancel();

  @override
  Future<void> close() {
    for (final transfer in _transfers.values) {
      transfer.cancel();
    }

    return super.close();
  }

  void _set(int messageId, AttachmentFile file) {
    emit(state.copyWith(files: {...state.files, messageId: file}));
  }
}
