import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// نسخةُ المتصفّح: التطبيقُ يملأ النافذة، وعناصرُه بأحجام الهاتف.
///
/// **كلُّ شاشةٍ في التطبيق مرسومةٌ لهاتفٍ عرضُه ٤٣٠**، وكلُّ `.w` و`.sp` نسبةٌ إلى ذلك العرض. على
/// شاشة حاسوبٍ عرضُها ١٤٤٠ كان كلُّ شيءٍ سيُرسم بثلاثة أضعافه: خطٌّ بحجم عنوان وأزرارٌ بعرض الشاشة.
/// فيُقال لـScreenUtil وحده إن «الجهاز» عرضُه [maxScaleWidth] على الأكثر — والشاشاتُ نفسها تأخذ
/// النافذة كاملة: الصفوفُ والبطاقات تمتدّ بعرضها، والحشوةُ والخطوط والأيقونات بقياس الهاتف.
///
/// **لا شيء من هذا على الهاتف**: خارج الويب تبقى ScreenUtil كما ضبطتها `ScreenUtilInit`.
abstract final class WebFrame {
  /// أعرضُ «جهاز» تُقاس عليه العناصر على الويب. أعرضُ قليلاً من ٤٣٠ المرجعي، فلا يكبر شيءٌ أكثر
  /// من عُشر حجمه، ولا تصغر الخطوط على الحاسوب.
  static const double maxScaleWidth = 480;

  /// يُنادى في `builder` الخاص بـ`ScreenUtilInit` قبل بناء التطبيق. `ScreenUtilInit` يقرأ النافذة
  /// نفسها (`View`) فيضبط المقياس على عرضها كاملاً؛ هنا يُعاد ضبطه على [maxScaleWidth].
  static void configureScreenUtil(BuildContext context, {required Size designSize}) {
    if (!kIsWeb) return;

    final window = MediaQueryData.fromView(View.of(context));

    ScreenUtil.configure(
      data: window.copyWith(
        size: Size(math.min(window.size.width, maxScaleWidth), window.size.height),
      ),
      designSize: designSize,
      minTextAdapt: true,
    );
  }

  /// أعرضُ ما تُرسم به صورةٌ تأخذ عرض الشاشة بنسبةٍ ثابتة — معرضُ المنتج، رمز QR، معاينة الكيس.
  static const double maxMediaWidth = 560;

  /// كم عموداً في شبكةٍ عمودان على الهاتف.
  ///
  /// على الهاتف [phone] كما هو. على الويب يتّسع العدد مع النافذة حتى لا ينزل عرضُ البلاطة عن
  /// [minTileWidth]، ولا يزيد على [count] إن عُرف عددُ البلاطات — صفٌّ واحدٌ بلا خاناتٍ فارغة.
  /// بلا هذا كانت بلاطتان تملآن ١٤٤٠ نقطة، كلٌّ منهما بحجم شاشة هاتفٍ كاملة.
  static int columns(
    BuildContext context, {
    required int phone,
    required double minTileWidth,
    int? count,
  }) {
    if (!kIsWeb) return phone;

    final fit = math.max(phone, MediaQuery.sizeOf(context).width ~/ minTileWidth);

    return count == null ? fit : math.max(phone, math.min(fit, count));
  }

  /// صورةٌ بنسبةٍ ثابتة لا تتمدّد على الويب أعرضَ من [maxMediaWidth]، في وسط ما حولها. على
  /// الهاتف [child] كما هو.
  static Widget media(Widget child) {
    if (!kIsWeb) return child;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxMediaWidth),
        child: child,
      ),
    );
  }

  /// يلفّ ما تحت الموجّه — الشاشات والنوافذ والأوراق السفلية.
  ///
  /// الفأرةُ تسحب كما يسحب الإصبع: شريطُ الإعلانات والقوائم الأفقية والسحبُ للتحديث مرسومةٌ للمس،
  /// وبلا هذا لا تتحرّك على الحاسوب إلا بعجلةٍ أفقية لا يملكها أكثرُ الناس.
  static Widget wrap(BuildContext context, Widget child) {
    if (!kIsWeb) return child;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: child,
    );
  }
}
