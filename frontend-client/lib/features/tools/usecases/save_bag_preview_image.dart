import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/tools/models/bag_preview_painter.dart';
import 'package:dayaa_client/features/tools/models/bag_type.dart';
import 'package:dayaa_client/features/tools/models/design_placement.dart';
import 'package:flutter/rendering.dart' show Canvas, Size, debugPrint;
import 'package:path_provider/path_provider.dart';

/// يرسم المعاينة صورةً ويكتبها حيث تستطيع ورقة المشاركة — أو مكتبة التصاميم — أن تأخذها.
///
/// **بلا خطوط إرشاد.** هي للعمل لا للنتيجة: الزبون الذي تصله معاينةٌ عليها إطارٌ متقطّع يسأل عن
/// إطارٍ لن يُطبع. وهذا هو الفرق الوحيد بين ما يُصدَّر وما كان على الشاشة، لأن الرسّام واحد.
class SaveBagPreviewImage {
  const SaveBagPreviewImage();

  /// الاسم المعروض. الاسم على القرص فريدٌ بطابعٍ زمني، لنفس سبب `SaveQrCodeImage`.
  static const String fileName = 'معاينة-التصميم.png';

  /// طول الضلع الأطول بالبكسل.
  ///
  /// معاينةٌ تُرسل للزبون على واتساب وتُفتح على هاتفه؛ ١٦٠٠ تكفيها وتزيد، ولا تُطبع منها أبداً —
  /// الطباعة تأخذ ملف التصميم الأصلي لا صورةً منه.
  static const int longestSide = 1600;

  Future<Either<Failure, String>> call({
    required BagType bag,
    required DesignPlacement placement,
    required ui.Image design,
    required ui.Image mockup,
  }) async {
    ui.Picture? picture;
    ui.Image? image;

    try {
      final size = _sizeFor(mockup);

      final recorder = ui.PictureRecorder();
      BagPreviewPainter(
        bag: bag,
        mockup: mockup,
        placement: placement,
        design: design,
        showGuides: false,
      ).paint(Canvas(recorder), size);

      picture = recorder.endRecording();
      image = await picture.toImage(size.width.round(), size.height.round());

      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        return const Left(Failure.unexpected(message: 'تعذّر تجهيز صورة المعاينة'));
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/bag-preview-${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      return Right(file.path);
    } on Object catch (error, stack) {
      debugPrint('⚠️ صورة المعاينة لم تُكتب: $error\n$stack');

      return Left(Failure.unexpected(message: 'تعذّر حفظ صورة المعاينة', cause: '$error'));
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  /// القماشة بنسبة صورة الكيس نفسها، فلا شريط فارغ حول المعاينة المصدَّرة.
  static Size _sizeFor(ui.Image mockup) {
    final longest = mockup.width > mockup.height ? mockup.width : mockup.height;
    final scale = longestSide / longest;

    return Size(mockup.width * scale, mockup.height * scale);
  }
}
