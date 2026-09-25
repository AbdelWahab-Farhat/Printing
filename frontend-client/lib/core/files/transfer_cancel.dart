import 'dart:async';

/// مقبضُ إلغاءٍ لنقلٍ جارٍ — رفعٍ أو تنزيل.
///
/// **بلا نوعٍ من Dio**، لأن ما فوق طبقة المستودعات لا يعرف Dio (RULES §0): الـCubit يمسك هذا،
/// والمستودع يترجمه إلى `CancelToken` عند الطلب.
///
/// **الإلغاء ليس فشلاً.** من ألغى يعرف أنه ألغى؛ فالمستدعي يسأل [isCancelled] بعد انتهاء النقل
/// قبل أن يرسم أيّ رسالة خطأ.
class TransferCancel {
  final Completer<void> _signal = Completer<void>();

  bool get isCancelled => _signal.isCompleted;

  /// يكتمل ساعةَ يُلغى النقل.
  Future<void> get whenCancelled => _signal.future;

  void cancel() {
    if (!_signal.isCompleted) _signal.complete();
  }
}
