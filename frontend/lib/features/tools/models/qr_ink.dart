import 'package:flutter/painting.dart' show Color;

/// ألوان رمز QR — وهي **حبرٌ لا ثيم**، ولهذا هي مكتوبة هنا بالهكس رغم §7.
///
/// القاعدة في §7 تمنع اللون الثابت لأن الثيم يتغيّر واللون المكتوب لا يتغيّر معه. هذه الألوان
/// ليست من الثيم في شيء: الموظف يختار حبراً سيُطبع على كيس، والصورة الخارجة منها تُفتح في
/// برنامج تصميم بعد ساعة. أبيضُ الخلفية هنا **أبيض**، لا `surface`؛ ولو أخذ لون السطح
/// (`#f4fbfa`) لخرج الرمز بمربّع مائل إلى الخضرة يظهر فوق أي ورق أبيض يُطبع عليه. وأسودُ الحبر
/// أسود في الوضعين الفاتح والداكن، لأن الكيس لا وضع داكن له.
///
/// وهو نفس الاستثناء الذي يشرحه `app_tones.dart`: لونٌ لا دور له في ماتيريال يُعرَّف مرة واحدة في مكان
/// واحد، لا في شاشة.
abstract final class QrInk {
  /// خلفية الرمز حين لا تكون شفافة. أبيض تام — انظر أعلاه.
  static const Color paper = Color(0xFFFFFFFF);

  /// الافتراضي، وهو ما تفتح عليه أداة الموقع (`value="#000000"`).
  static const Color black = Color(0xFF000000);

  /// الألوان السريعة — صفٌّ واحد تحت الحقل.
  ///
  /// **ليست كل ما يستطيع الموظف اختياره**: بجانبها منتقٍ يفتح على أي لون
  /// ([QrInkPicker])، وهذه اختصارٌ لما يُختار في أغلب المرّات لا قائمةٌ مغلقة.
  ///
  /// **ستة، وهي محسوبة لا مختارة ذوقاً:** الصفّ يجب أن يبقى صفاً واحداً على عرض الهاتف مع
  /// المنتقي في آخره، وسبعة أقراص هي ما يسعه ٤٣٠ منطقياً. زيادةُ لونٍ سابعٍ تدفع القرص الأخير
  /// خارج الشاشة أو تلفّ الصفّ سطرين.
  ///
  /// وكلها داكنة: الماسح يقرأ تبايناً بين الحبر والخلفية، ورمزٌ فاتح على أبيض لا يُقرأ مهما بدا
  /// جميلاً على الشاشة. المنتقي يسمح بالفاتح لمن أراده صراحةً؛ أما ما يُختار بنقرةٍ واحدة بلا
  /// تفكير فيُقرأ دائماً.
  static const List<Color> palette = [
    black,
    Color(0xFF1F2937), // رمادي فحمي
    Color(0xFFB91C1C), // أحمر
    Color(0xFF14532D), // أخضر داكن
    Color(0xFF1E3A8A), // أزرق داكن
    Color(0xFF4C1D95), // بنفسجي
  ];

  /// The lowest ink-to-paper contrast a scanner reads without trouble.
  ///
  /// 3:1 is WCAG's floor for graphics. Pure red (`#FF0000`, 4:1) passes and orange
  /// (`#FF8800`, about 2.4:1) does not, which matches what phone scanners manage on white.
  static const double minContrast = 3;

  /// Whether [ink] is too light on white paper to scan reliably.
  ///
  /// A warning, never a refusal: somebody printing on a dark bag may want exactly this ink.
  static bool isLowContrast(Color ink) =>
      (paper.computeLuminance() + .05) / (ink.computeLuminance() + .05) < minContrast;
}
