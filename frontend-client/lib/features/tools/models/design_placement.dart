import 'dart:math' as math;
import 'dart:ui';

import 'package:dayaa_client/features/tools/models/bag_type.dart';

/// أين يقف التصميم داخل منطقة الطباعة، وكم كُبِّر — **وما لا يستطيع تجاوزه**.
///
/// **هذا الملف هو الأداة.** كل ما عداه رسمٌ وأزرار؛ وهنا وحده يُقرَّر أن التصميم لا يدخل الهامش.
/// ولذلك هو خالصٌ تماماً: لا ويدجت، ولا قماشة، ولا `BuildContext` — دالّتان على أعداد، تُختبران
/// بلا شجرة. الشرط الذي يحميانه ينكسر بصمت (تصميمٌ زحف سنتيمتراً داخل الطيّة يبدو سليماً على
/// الشاشة ويُكتشف على ألف كيس مطبوع)، وما ينكسر بصمت يجب أن يكون أسهلَ ما يُختبر.
///
/// ## الإزاحة كسرٌ لا بكسل
///
/// [offset] نسبةٌ من مقاس منطقة الطباعة، لا بكسلات على شاشةٍ بعينها. وهذا ليس تدقيقاً: المعاينة
/// تُرسم بمقاسٍ على الهاتف وبمقاسٍ آخر عند التصدير وبثالثٍ حين يُدار الجهاز — ولو حُفظت
/// الإزاحة بالبكسل لانزلق التصميم على الكيس في كل مرة، وهو أسوأ ما يمكن أن تفعله معاينة.
class DesignPlacement {
  const DesignPlacement({required this.scale, required this.offset});

  /// التصميم يملأ منطقة الطباعة بلا قصٍّ، في وسطها.
  const DesignPlacement.initial() : scale = 1, offset = Offset.zero;

  /// مضاعِفٌ فوق «المقاس الذي يدخل المنطقة كاملاً»: ١ يعني يملأها بلا قصّ.
  final double scale;

  /// الإزاحة عن مركز المنطقة، **كسراً من مقاسها** — انظر أعلاه.
  final Offset offset;

  /// أصغرُ وأكبرُ تكبيرٍ مسموح.
  ///
  /// تصميمٌ بربع مقاسه شعارٌ صغير في وسط الكيس، وهو استعمالٌ حقيقي. وأكبر من ستة أضعاف لا يظهر
  /// منه إلا بضع بكسلات مكبَّرة، وهي ليست معاينة لشيء.
  static const double minScale = .25;
  static const double maxScale = 6;

  /// منطقة الطباعة داخل وجه الكيس، حيثما وقع ذلك الوجه.
  ///
  /// [bagRect] هو **وجه الكيس** لا الصورة كلها — انظر `BagPreviewPainter.faceIn`. والهوامش
  /// تُقتطع منه بنسبتها من الكيس الحقيقي، فالرسم تصغيرٌ أمين للسنتيمترات: هامش ٢ سم من كيسٍ
  /// عرضه ٣٥ هو ٥٫٧١٪ من عرض وجهه المرسوم، أياً كان ذلك العرض.
  static Rect printAreaIn(Rect bagRect, BagType bag) {
    return Rect.fromLTRB(
      bagRect.left + bagRect.width * (bag.marginStart / bag.width),
      bagRect.top + bagRect.height * (bag.marginTop / bag.height),
      bagRect.right - bagRect.width * (bag.marginEnd / bag.width),
      bagRect.bottom - bagRect.height * (bag.marginBottom / bag.height),
    );
  }

  /// أين يقع التصميم ذو المقاس [designSize] داخل [printArea] بهذا الوضع.
  Rect rectIn(Rect printArea, Size designSize) {
    final size = _sizeIn(printArea, designSize);

    return Rect.fromCenter(
      center: printArea.center + Offset(offset.dx * printArea.width, offset.dy * printArea.height),
      width: size.width,
      height: size.height,
    );
  }

  /// نفس الوضع، مردوداً إلى ما تسمح به منطقة الطباعة.
  ///
  /// **قاعدةٌ واحدة تخدم الحالتين، وهي أنيقة لأنها صادقة:** أقصى إزاحة على أي محور هي نصفُ
  /// **فرق** المقاسين مطلقاً.
  ///
  ///   * تصميمٌ **أصغر** من المنطقة: الفرق هو الخلوّ حوله، فيتحرّك داخله ويقف عند الحافة — ولا
  ///     يخرج إلى الهامش.
  ///   * تصميمٌ **أكبر** منها: الفرق هو ما يفيض عنها، فيتحرّك بمقداره ويظلّ مغطّياً المنطقة
  ///     كلها — فلا تنفتح فجوةٌ بيضاء بين طرفه والهامش. وما فاض يقصّه الرسم.
  ///
  /// الحالتان بمعادلةٍ واحدة لأن كليهما يقول الشيء نفسه: **حافة التصميم لا تعبر حافة منطقة
  /// الطباعة، لا إلى الداخل ولا إلى الخارج.**
  DesignPlacement clamped(Rect printArea, Size designSize) {
    final size = _sizeIn(printArea, designSize);

    final limitX = (printArea.width - size.width).abs() / 2 / printArea.width;
    final limitY = (printArea.height - size.height).abs() / 2 / printArea.height;

    return DesignPlacement(
      scale: scale,
      offset: Offset(
        offset.dx.clamp(-limitX, limitX),
        offset.dy.clamp(-limitY, limitY),
      ),
    );
  }

  /// نفس الوضع بتكبيرٍ مضروب في [factor]، محصوراً بين الحدّين.
  DesignPlacement scaledBy(double factor) =>
      DesignPlacement(scale: (scale * factor).clamp(minScale, maxScale), offset: offset);

  /// نفس الوضع مزاحاً بـ[delta] بكسلاً داخل [printArea].
  DesignPlacement movedBy(Offset delta, Rect printArea) => DesignPlacement(
    scale: scale,
    offset: offset + Offset(delta.dx / printArea.width, delta.dy / printArea.height),
  );

  /// مقاس التصميم مرسوماً: أكبرُ مقاسٍ يدخل المنطقة بنسبته، مضروباً في [scale].
  ///
  /// «يدخل بنسبته» لا «يملأ»: تصميمٌ مربّع على منطقةٍ مستطيلة يُمطّ ليملأها، والمطّ يشوّه شعار
  /// الزبون — وهو خطأ يراه الزبون قبل أن يراه أحد.
  Size _sizeIn(Rect printArea, Size designSize) {
    final fit = math.min(
      printArea.width / designSize.width,
      printArea.height / designSize.height,
    );

    return Size(designSize.width * fit * scale, designSize.height * fit * scale);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignPlacement && other.scale == scale && other.offset == offset;

  @override
  int get hashCode => Object.hash(scale, offset);
}
