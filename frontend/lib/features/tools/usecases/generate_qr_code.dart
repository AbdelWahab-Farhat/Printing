import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/tools/models/qr_code_art.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:qr/qr.dart';

/// يرمّز ما كتبه الموظف رمزَ QR.
///
/// **محليّ بالكامل — لا خادم ولا مستودع.** الترميز حسابٌ على الجهاز، ولا شيء هنا يُحفظ ولا
/// يُقرأ من مصدر بيانات، فالمستودع المجرّد كان سيكون عقداً بلا طرف ثانٍ. هذا نفس شكل
/// [SaveOrderInvoicePdf]: حالة استعمال بلا مستودع، تعيد `Either` لأن ما تحتها يرمي.
class GenerateQrCode {
  const GenerateQrCode();

  Either<Failure, QrCodeArt> call(String data) {
    try {
      return Right(QrCodeArt.encode(data));
    } on InputTooLongException catch (error) {
      // الفشل الوحيد المتوقَّع، وله رسالته: أكبر رمز (الإصدار ٤٠ بتصحيح `H`) يسع نحو ألف حرف
      // لاتيني — ونصفها عربية، إذ يأخذ الحرف العربي بايتين في UTF-8. الموظف الذي لصق صفحة
      // كاملة يستحق أن يُقال له إنها طويلة، لا «حدث خطأ ما».
      return Left(
        Failure.unexpected(
          message: 'المحتوى أطول مما يسعه رمز QR واحد، اختصره وحاول مجدداً',
          cause: '$error',
        ),
      );
    } on Object catch (error, stack) {
      // واسعة عمداً، على سنّة [SaveOrderInvoicePdf]: خلف هذا السطر مرمِّزٌ كامل، وسقوطه بأي شكل
      // آخر يجب أن يصل الموظف جملةً لا شاشةً حمراء. والسبب يُحمل في `cause` لأن الجملة وحدها
      // لا يُعمل بها حين تُنقل عن هاتف.
      debugPrint('⚠️ تعذّر ترميز رمز QR: $error\n$stack');

      return Left(Failure.unexpected(message: 'تعذّر إنشاء الرمز', cause: '$error'));
    }
  }
}
