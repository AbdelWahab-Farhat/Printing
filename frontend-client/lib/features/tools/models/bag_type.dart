import 'dart:ui' show Rect;

/// نوع الكيس: صورته، ومقاسه الحقيقي، وهوامشه، وأين يقع وجهه داخل الصورة.
///
/// **enum لا قائمةَ كائنات**، فالأنواع خمسة معروفة بأسمائها: `switch` عليها شامل، ولا يمكن أن
/// يصل إلى الشاشة نوعٌ لا صورة له.
///
/// ## الأرقام الستة، ولماذا لا تكفي وحدها هنا
///
/// منطقة الطباعة تُشتقّ من المقاس ناقص الهوامش — ٣٥ ناقص ٢ من كل جانب = ٣١ سم. لكن الكيس هنا
/// **صورةٌ فوتوغرافية** لا مستطيلٌ مرسوم: الكيس يشغل جزءاً من الإطار، وحوله ظلٌّ وخلفية. فلا
/// يكفي أن نعرف الهوامش بالسنتيمتر، بل يجب أن نعرف **أين وجه الكيس داخل الصورة** أولاً —
/// وهذا [face]. ثم تُقتطع الهوامش من ذلك الوجه بنسبتها، فتعطي منطقة الطباعة.
///
/// وهكذا يبقى الحساب واحداً: `DesignPlacement.printAreaIn` تأخذ مستطيل الكيس وتقتطع منه
/// الهوامش، سواءٌ جاء ذلك المستطيل من شكلٍ مرسوم أو من وجهٍ داخل صورة.
///
/// ## ⚠️ الأرقام أدناه **تقديرية وتنتظر معايرة**
///
/// **الصور مأخوذة من `daaya.ly/preview.html`، وأداة الموقع لا تعرف منطقة طباعة إطلاقاً** — هي
/// ترسم الكيس ملءَ القماشة وتترك الشعار يُسحب أينما شاء. فلا شيء من [face] ولا من الهوامش جاء
/// من هناك: قِيَم [face] مقيسةٌ بالعين من كل صورة، والمقاسات والهوامش مقترحةٌ لكل نوع.
///
/// **ما يجب أن يُراجَع مع المطبعة قبل أن يُعتمد على المعاينة في قرار طباعة:** المقاسات الحقيقية
/// لكل نوع، وهوامشه الأربعة. أما [face] فيُصحَّح بالنظر إلى المعاينة نفسها: إن بدا الإطار
/// المتقطّع مزاحاً عن وجه الكيس، فهذه أرقامه.
enum BagType {
  /// المثال الذي ورد في المواصفة حرفياً: ٣٥ سم بهامش ٢ ⇒ ٣١ سم متاحة.
  shipping(
    label: 'أكياس شحن',
    asset: 'assets/mockups/shipping-bag.webp',
    width: 35,
    height: 45,
    marginTop: 2,
    marginBottom: 2,
    marginStart: 2,
    marginEnd: 2,
    face: Rect.fromLTRB(.27, .27, .72, .80),
  ),

  /// الشريط المُحكم في أعلى الكيس لا يُطبع، فهامشه العلوي أكبر.
  transparent(
    label: 'أكياس شفافة',
    asset: 'assets/mockups/transparent-bag.webp',
    width: 30,
    height: 40,
    marginTop: 4,
    marginBottom: 2,
    marginStart: 2,
    marginEnd: 2,
    face: Rect.fromLTRB(.21, .32, .74, .80),
  ),

  /// الكيس الورقي له طيّةٌ عرضية في أسفله، فالوجه المطبوع هو ما فوقها.
  paper(
    label: 'أكياس ورقية',
    asset: 'assets/mockups/paper-bag.webp',
    width: 32,
    height: 42,
    marginTop: 3,
    marginBottom: 3,
    marginStart: 2,
    marginEnd: 2,
    face: Rect.fromLTRB(.32, .29, .68, .60),
  ),

  /// اليد المقطوعة في أعلى الكيس تأكل خمسة سنتيمترات لا يُطبع فيها شيء.
  innerHandle(
    label: 'أكياس يد داخلية',
    asset: 'assets/mockups/handle.jpg',
    width: 30,
    height: 40,
    marginTop: 5,
    marginBottom: 2,
    marginStart: 2,
    marginEnd: 2,
    face: Rect.fromLTRB(.29, .30, .69, .76),
  ),

  /// اليد الخارجية مثبّتة فوق حافة الكيس، فالحافة نفسها لا تُطبع.
  outerHandle(
    label: 'حقيبة يد خارجية',
    asset: 'assets/mockups/outer-hand-bag.webp',
    width: 35,
    height: 40,
    marginTop: 4,
    marginBottom: 2,
    marginStart: 2,
    marginEnd: 2,
    face: Rect.fromLTRB(.28, .28, .72, .78),
  );

  const BagType({
    required this.label,
    required this.asset,
    required this.width,
    required this.height,
    required this.marginTop,
    required this.marginBottom,
    required this.marginStart,
    required this.marginEnd,
    required this.face,
  });

  /// ما يُقرأ في القائمة.
  final String label;

  /// صورة الكيس، من `daaya.ly`.
  final String asset;

  /// مقاس الكيس كاملاً بالسنتيمتر.
  final double width;
  final double height;

  /// ما لا يُطبع فيه بالسنتيمتر، من كل جهة.
  ///
  /// `start`/`end` لا `left`/`right`: التطبيق يُقرأ من اليمين، و«الأيمن» في ورقة المواصفات هو
  /// بداية الكيس لا يساره على الشاشة.
  final double marginTop;
  final double marginBottom;
  final double marginStart;
  final double marginEnd;

  /// أين يقع **وجه الكيس** داخل [asset]، كسوراً من عرض الصورة وارتفاعها.
  ///
  /// وجه الكيس كاملاً — لا منطقة الطباعة: الهوامش تُقتطع منه بعد ذلك، فيبقى معنى الأرقام
  /// الستة قائماً ولا يُخلط قياسُ صورةٍ بقياس منتج.
  final Rect face;

  /// عرض منطقة الطباعة بالسنتيمتر — ٣٥ ‎−‎ ٢ ‎−‎ ٢ = ٣١.
  double get printableWidth => width - marginStart - marginEnd;

  double get printableHeight => height - marginTop - marginBottom;

  /// هل الأرقام تصف كيساً يمكن الطباعة عليه أصلاً؟
  ///
  /// هوامشُ أكبر من الكيس تعطي مساحةً سالبة، وهي لا تُرسم ولا تُقصّ ولا تعني شيئاً.
  bool get isPrintable => printableWidth > 0 && printableHeight > 0;

  /// ما تفتح عليه الشاشة.
  ///
  /// حقلٌ ثابت لا getter، ليصلح داخل تعبيرٍ `const` — وحالة الشاشة الابتدائية كذلك.
  static const BagType initial = shipping;
}
