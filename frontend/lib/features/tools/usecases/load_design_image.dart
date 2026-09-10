import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// يفكّ ترميز التصميم المرفوع صورةً جاهزة للرسم.
///
/// **PDF يُرفض هنا برسالته**، وهو الفخّ الوحيد في هذا الملف: مكتبة تصاميم العميل تقبل الـ PDF
/// (`DesignRules.extensions`) لأنه ما يرسله المصمّم غالباً، وهذه المعاينة لا تستطيع رسمه — لا
/// مُصيِّر PDF في التطبيق، وإضافته محرّكٌ أصلي كامل من أجل معاينة. فالرسالة تقول للموظف ماذا
/// يفعل بدل أن تتركه أمام شاشةٍ لا يظهر فيها شيء.
class LoadDesignImage {
  const LoadDesignImage();

  Future<Either<Failure, ui.Image>> call(PickedFile file) async {
    if (file.name.toLowerCase().endsWith('.pdf')) {
      return const Left(
        Failure.unexpected(
          message: 'المعاينة تحتاج صورة — حوّل ملف PDF إلى PNG أو JPG ثم ارفعه',
        ),
      );
    }

    try {
      final bytes = await File(file.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();

      return Right(frame.image);
    } on Object catch (error, stack) {
      // واسعة عمداً: تحتها نظام ملفات ومفكِّك ترميز صور، وأيٌّ منهما قد يكون من سقط — ملفٌ
      // مُصدَّر بامتداد يكذب على محتواه يصل إلى هنا صورةً لا تُفكّ.
      debugPrint('⚠️ التصميم لم يُقرأ: $error\n$stack');

      return Left(Failure.unexpected(message: 'تعذّر قراءة ملف التصميم', cause: '$error'));
    }
  }
}
