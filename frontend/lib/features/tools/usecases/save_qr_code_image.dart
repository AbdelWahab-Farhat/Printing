import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/tools/models/qr_code_art.dart';
import 'package:dayaa/features/tools/models/qr_code_painter.dart';
import 'package:flutter/rendering.dart' show Canvas, Color, Size, debugPrint;
import 'package:path_provider/path_provider.dart';

/// يرسم الرمز صورةً PNG ويكتبها حيث تستطيع ورقة المشاركة أن تأخذها.
///
/// **المجلد المؤقت، لا «المستندات»** — نفس نداء [SaveOrderInvoicePdf] ولنفس السبب: الملف ساعٍ،
/// يعيش الثواني التي بين «تحميل الصورة» والورقة التي يختار فيها الموظف الصور أو الملفات أو
/// واتساب. ولا شيء هنا ملكُ الخادم أصلاً — الرمز يُعاد توليده من نصّه في أي لحظة.
class SaveQrCodeImage {
  const SaveQrCodeImage();

  /// الاسم **المعروض**: في ورقة المشاركة، وحيثما يُحفظ، وفي مكتبة تصاميم العميل. نفس اسم
  /// الموقع (`QR-Code.png`).
  ///
  /// **وهو غير اسم الملف على القرص عمداً.** الملف على القرص يحمل طابعاً زمنياً يجعله فريداً،
  /// لأنه ساعٍ قد يكون طائراً إلى الخادم بينما يُنشئ الموظف رمزاً ثانياً — واسمٌ ثابت كان يعني
  /// أن الرمز الثاني يكتب فوق الأول **وهو قيد الرفع**، فيصل إلى مكتبة العميل رمزٌ لم يطلبه أحد.
  /// وورقة المشاركة تأخذ الاسم المعروض عبر `fileNameOverrides`، فلا يرى المستخدم الطابع الزمني.
  static const String fileName = 'QR-Code.png';

  /// طول الضلع المطلوب بالبكسل، قبل التقريب في [_sideFor].
  ///
  /// **١٠٢٤ لا ٢٥٦ التي في الموقع، وهذا فرقٌ مقصود.** ٢٥٦ مقاس معاينةٍ على شاشة؛ وهذه الصورة
  /// تذهب إلى تصميمٍ يُطبع على كيس، فتُكبَّر. رمزٌ مكبَّر من ٢٥٦ بكسل يخرج بحوافّ مهترئة يقرأها
  /// الماسح مرة ويخطئها مرة، والفرق في الحجم على القرص بضع عشرات من الكيلوبايتات.
  static const int targetSize = 1024;

  /// المسار المكتوب، جاهزاً للمشاركة.
  Future<Either<Failure, String>> call({
    required QrCodeArt art,
    required Color color,
    required bool transparentBackground,
  }) async {
    ui.Picture? picture;
    ui.Image? image;

    try {
      final side = _sideFor(art);

      final recorder = ui.PictureRecorder();
      QrCodePainter(
        art: art,
        color: color,
        transparentBackground: transparentBackground,
      ).paint(Canvas(recorder), Size(side.toDouble(), side.toDouble()));

      picture = recorder.endRecording();
      image = await picture.toImage(side, side);

      // PNG لا JPEG: الأخير لا يعرف الشفافية أصلاً، ويضع حول كل حافة حادّة تموّجاً هو بالضبط
      // ما يخلط على الماسح قراءة الوحدات الصغيرة.
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        return const Left(Failure.unexpected(message: 'تعذّر تجهيز صورة الرمز'));
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr-${DateTime.now().microsecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      return Right(file.path);
    } on Object catch (error, stack) {
      // واسعة عمداً: تحتها مُصيّرٌ ومُرمِّز صور ونظام ملفات، وأيٌّ من الثلاثة قد يكون من سقط.
      debugPrint('⚠️ صورة الرمز لم تُكتب: $error\n$stack');

      return Left(Failure.unexpected(message: 'تعذّر حفظ صورة الرمز', cause: '$error'));
    } finally {
      // كلاهما يحمل ذاكرة خارج كومة دارت، ولا يحرّرها جامع القمامة.
      image?.dispose();
      picture?.dispose();
    }
  }

  /// أقرب ضلعٍ إلى [targetSize] يقبل القسمة على عدد الوحدات بلا باقٍ.
  ///
  /// **وهذا هو الفرق بين رمزٍ حادّ ورمزٍ يكاد يُقرأ.** لو رُسم ٣٣ وحدة على ١٠٢٤ بكسل لصار عرض
  /// الوحدة ٣١٫٠٣ بكسلاً، فتخرج بعض الوحدات أعرض من جاراتها ببكسل ويتذبذب الشبك الذي يعتمد عليه
  /// الماسح. بضربٍ صحيح تخرج كل وحدة بنفس العرض تماماً، والثمن أن الضلع ١٠٢٣ بدل ١٠٢٤.
  static int _sideFor(QrCodeArt art) {
    final modules = art.canvasModules;

    return math.max(1, targetSize ~/ modules) * modules;
  }
}
