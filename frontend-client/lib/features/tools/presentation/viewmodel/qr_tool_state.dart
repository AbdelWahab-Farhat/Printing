part of 'qr_tool_cubit.dart';

/// ما يمكن أن يكون على الشاشة، ولا شيء غيره.
///
/// ثلاث حالات لا حقلان قابلان للعدم: الشكل الآخر يسمح بـ «رمزٌ موجود، وفشلٌ موجود» معاً — وهي
/// الحالة التي تُبقي رمزاً قديماً معروضاً تحت رسالة خطأ عن رمزٍ جديد، فيحمّل الموظف الأول
/// ظانّاً أنه الثاني.
@freezed
sealed class QrToolState with _$QrToolState {
  /// لم يُضغط «إنشاء الرمز» بعد — أو ضُغط وفشل. مكان المعاينة فارغ.
  const factory QrToolState.blank() = QrBlank;

  const factory QrToolState.ready({required QrCodeArt art}) = QrReady;

  /// المحتوى لا يسعه رمز. الرسالة تذهب توستاً، والمعاينة تبقى فارغة — انظر أعلاه.
  const factory QrToolState.failure(Failure failure) = QrToolFailure;
}
