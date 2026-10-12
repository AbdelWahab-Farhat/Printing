import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';

/// أين انتهى الملف على الهاتف — وهو ما يقوله الإشعار بعد «تحميل».
enum SavePlace {
  /// «الصور» على آيفون، والمعرض على أندرويد.
  photos,

  /// «التنزيلات» على أندرويد.
  downloads,

  /// «الملفات» على آيفون: «على الـiPhone» ← مجلد التطبيق. لا «تنزيلات» مشتركة هناك.
  files,

  /// مكانٌ اختاره صاحبه من نافذة «حفظ باسم» — أندرويد ٩ وما قبله حين لا إذن تخزين.
  chosen,
}

/// يحفظ ملفاً حيث يجده صاحبه بعدها، **بلا ورقة مشاركة**.
///
/// **واجهةٌ لا نداءٌ مباشر**: الإضافة لا تعمل تحت `flutter_test`، وتنفيذٌ مزيّف يكفي لاختبار من
/// يقرّر المكان. وكلا الندائين يأخذ ملفاً مكتوباً على القرص لا بايتات، فلا يُحمل الملف في الذاكرة
/// مرتين.
///
/// `Right(null)` يعني أن صاحبه أغلق نافذة «حفظ باسم»: لم يُحفظ شيء، ولم يخطئ أحد.
abstract interface class DeviceSaver {
  /// إلى «الصور». وما ترفضه — إذنٌ مُنع، أو صيغةٌ لا تقبلها مكتبة الصور — يذهب إلى [toFiles].
  Future<Either<Failure, SavePlace?>> toPhotos({required String path, required String mimeType});

  /// إلى «التنزيلات» على أندرويد، و«الملفات» على آيفون.
  Future<Either<Failure, SavePlace?>> toFiles({required String path, required String mimeType});
}
