part of 'attachment_files_cubit.dart';

/// أين ملفُّ رسالةٍ واحدة بالنسبة إلى هذا الهاتف.
@freezed
sealed class AttachmentFile with _$AttachmentFile {
  /// على الخادم وحده — سهمُ تنزيل.
  const factory AttachmentFile.remote() = AttachmentRemote;

  /// يُنزَّل الآن. [progress] من ٠ إلى ١؛ ٠ حين لم يقل الخادم الحجم بعد.
  const factory AttachmentFile.downloading({@Default(0) double progress}) = AttachmentDownloading;

  /// على الهاتف — يُفتح بلمسة.
  const factory AttachmentFile.local(String path) = AttachmentLocal;

  /// فشل التنزيل؛ لمسةٌ تعيده. الرسالة نفسها في المحادثة لم يمسّها شيء.
  const factory AttachmentFile.failed(Failure failure) = AttachmentDownloadFailed;
}

/// ملفات المحادثة كلها، برقم الرسالة.
@freezed
abstract class AttachmentFilesState with _$AttachmentFilesState {
  const factory AttachmentFilesState({
    @Default(<int, AttachmentFile>{}) Map<int, AttachmentFile> files,
  }) = _AttachmentFilesState;
}

extension AttachmentFilesStateX on AttachmentFilesState {
  /// ما لم يُسأل عنه بعد على الخادم وحده، حتى يقول الهاتف غير ذلك.
  AttachmentFile of(int messageId) => files[messageId] ?? const AttachmentFile.remote();
}
