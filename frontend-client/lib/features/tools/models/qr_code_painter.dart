import 'package:dayaa_client/features/tools/models/qr_code_art.dart';
import 'package:dayaa_client/features/tools/models/qr_ink.dart';
import 'package:flutter/rendering.dart';

/// يرسم [QrCodeArt] على أي قماشة بأي مقاس.
///
/// **رسّامٌ واحد للشاشة وللملف، وهذا هو سبب وجوده في `models/`.** الشاشة ترسم به داخل
/// `CustomPaint`، و[SaveQrCodeImage] ترسم به داخل `PictureRecorder` — فما يُحمَّل هو حرفياً ما
/// كان معروضاً، لا صورةٌ ثانية بُنيت بمنطق ثانٍ قد ينحرف عنه بعد تعديل. رسّامان لنفس الرمز هو
/// الطريق المعروف إلى «الصورة المحمَّلة تختلف عن المعاينة».
///
/// ولم يُلتقط الويدجت نفسه عبر `RepaintBoundary` بدلاً من ذلك، لأن ذلك يربط دقّة الملف بكثافة
/// شاشة الهاتف الذي ضُغط عليه: نفس الزر يُخرج صورة أوضح على جهاز أغلى.
class QrCodePainter extends CustomPainter {
  const QrCodePainter({
    required this.art,
    required this.color,
    required this.transparentBackground,
  });

  final QrCodeArt art;

  /// حبر الوحدات المطبوعة.
  final Color color;

  /// حين تكون الخلفية شفافة لا يُرسم شيء تحت الوحدات — فتُسقَط الصورة على التصميم كما هي.
  final bool transparentBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = art.canvasModules;
    final cell = size.shortestSide / modules;

    if (!transparentBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = QrInk.paper);
    }

    // بلا تنعيم حواف: حافة الوحدة يجب أن تكون حادّة لا متدرّجة، لأن الماسح يقرأ العتبة بين
    // فاتح وداكن، والتدرّج الرمادي على كل حافة هو ما يجعل رمزاً صغيراً يُقرأ من المحاولة
    // الثالثة.
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    for (var row = 0; row < art.moduleCount; row++) {
      for (var col = 0; col < art.moduleCount; col++) {
        if (!art.isDark(row, col)) continue;

        // الحواف تُقرَّب إلى الخارج: `floor` للبداية و`ceil` للنهاية. حين يكون [cell] عدداً
        // صحيحاً — وهو ما تضمنه [SaveQrCodeImage] للملف — لا يغيّر التقريب شيئاً. وحين لا يكون،
        // في المعاينة على الشاشة، تتداخل الوحدات المتجاورة بأقل من بكسل بدل أن يفصلها خيط
        // فاتح: الخيط الفاصل هذا يكسر قراءة الرمز من الشاشة، والسِّمَن الذي لا يتجاوز بكسلاً لا
        // يكسر شيئاً.
        final left = ((col + QrCodeArt.quietZone) * cell).floorToDouble();
        final top = ((row + QrCodeArt.quietZone) * cell).floorToDouble();
        final right = ((col + QrCodeArt.quietZone + 1) * cell).ceilToDouble();
        final bottom = ((row + QrCodeArt.quietZone + 1) * cell).ceilToDouble();

        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
      }
    }
  }

  @override
  bool shouldRepaint(QrCodePainter oldDelegate) =>
      !identical(oldDelegate.art, art) ||
      oldDelegate.color != color ||
      oldDelegate.transparentBackground != transparentBackground;
}
