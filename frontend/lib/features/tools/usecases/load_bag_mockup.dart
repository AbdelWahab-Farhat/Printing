import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

/// يفكّ ترميز صورة الكيس من أصول التطبيق.
///
/// **تُفكّ مرة واحدة لعمر العملية.** الصور خمس، مجموعها نحو ١٣٠ كيلوبايت، ولا تتغيّر أبداً —
/// فذاكرةٌ لا يمكن أن تبيت. وبدون الحفظ، كل تبديلٍ للمقاس يعيد فكّ الترميز، والموظف يبدّل
/// المقاس ثلاث مرات في الدقيقة ليجرّب شعاره على الأنواع.
///
/// **ولا `dispose` لما فيها**: هي مشتركة بين كل من يفتح الشاشة، والتخلّص منها في شاشةٍ يترك
/// الشاشة التالية ترسم بصورةٍ مُتلَفة. هذا هو الفرق بينها وبين تصميم الزبون في
/// [BagPreviewCubit] — ذاك يخصّ فتحةً واحدة ويُفرَج عنه معها.
class LoadBagMockup {
  const LoadBagMockup();

  static final Map<BagType, ui.Image> _cache = {};

  Future<Either<Failure, ui.Image>> call(BagType bag) async {
    if (_cache[bag] case final cached?) return Right(cached);

    try {
      final data = await rootBundle.load(bag.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();

      return Right(_cache[bag] = frame.image);
    } on Object catch (error, stack) {
      // أصلٌ مفقود من الحزمة أو غير مسجَّل في `pubspec.yaml` يصل إلى هنا، وهو خطأ بناءٍ لا خطأ
      // مستخدم — لكنه يظهر في يده، فيستحق جملةً تقول أي شيء لم يُقرأ.
      debugPrint('⚠️ صورة الكيس «${bag.label}» لم تُقرأ: $error\n$stack');

      return Left(
        Failure.unexpected(message: 'تعذّر تحميل صورة الكيس', cause: '$error'),
      );
    }
  }
}
