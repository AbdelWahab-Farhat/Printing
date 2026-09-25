import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';

/// ملفات المحادثة على هذا الهاتف: هل نُزّل ملفُّ رسالةٍ من قبل، وأين، وكيف يُنزَّل.
///
/// **واجهةٌ لا نداءٌ مباشر**، كـ`AttachmentPicker`: القرص والشبكة خلفها لا يعملان تحت
/// `flutter_test`، وتنفيذٌ مزيّف يعيد مساراً يكفي لاختبار الـCubit والشاشة كاملين.
///
/// [key] هويّةُ الملف الدائمة — رقم الرسالة عادةً — **لا الرابط**: الرابط موقَّعٌ يتغيّر مع كل
/// قراءة، والملف خلفه لا يتغيّر.
abstract interface class AttachmentStore {
  /// مسار الملف إن كان على الهاتف، وإلا `null`.
  Future<String?> localPath({required String key, required String fileName});

  /// ينزّل [url] ويُرجع مساره على الهاتف.
  ///
  /// [onProgress] من ٠ إلى ١ ما دام الخادم قال الحجم. **الملف يُكتب باسمٍ مؤقت ثم يُنقل**، فلا
  /// يبدو ملفٌّ انقطع تنزيله في منتصفه ملفاً كاملاً في المرة القادمة.
  Future<Either<Failure, String>> download({
    required String url,
    required String key,
    required String fileName,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  });
}
