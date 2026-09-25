part of 'bag_preview_cubit.dart';

/// ما يمكن أن يكون على شاشة المعاينة.
///
/// **الكيس في كل حال، لأنه لا حال بلا كيس.** الشاشة تفتح على مقاسٍ مختار وترسمه قبل أن يُرفع
/// شيء — فالكيس ليس نتيجةً تُنتظر، بل الأرضية التي يقف عليها كل ما عداه. وحين يحمله كلُّ فرعٍ
/// من الاتحاد يرفعه Freezed إلى الأصل من تلقائه، فيُقرأ `state.bag` بلا `switch` في كل شاشة.
@freezed
sealed class BagPreviewState with _$BagPreviewState {
  /// كيسٌ مختار ولا تصميم بعد.
  const factory BagPreviewState.empty({
    required BagType bag,
    ui.Image? mockup,
  }) = BagPreviewEmpty;

  /// ملفٌ يُفكّ ترميزه.
  const factory BagPreviewState.loading({
    required BagType bag,
    ui.Image? mockup,
  }) = BagPreviewLoading;

  const factory BagPreviewState.ready({
    required BagType bag,
    required ui.Image design,
    ui.Image? mockup,
  }) = BagPreviewReady;

  /// الملف لم يُقرأ — PDF مثلاً، أو صورةٌ تالفة.
  const factory BagPreviewState.failure({
    required BagType bag,
    required Failure failure,
    ui.Image? mockup,
  }) = BagPreviewFailure;

  const BagPreviewState._();

  /// التصميم المعروض، إن وُجد.
  ui.Image? get design => switch (this) {
    BagPreviewReady(:final design) => design,
    _ => null,
  };

  /// نفس الحال بكيسٍ آخر — التصميم المعروض يبقى كما هو، وصورة الكيس تُنتظر.
  ///
  /// [mockup] تُصفَّر عمداً: صورة الكيس السابق ليست صورة هذا، وإبقاؤها لحظةً يُري الموظف
  /// تصميمه على كيسٍ لم يعد مختاراً.
  BagPreviewState withBag(BagType bag) => switch (this) {
    BagPreviewReady(:final design) => BagPreviewState.ready(bag: bag, design: design),
    BagPreviewLoading() => BagPreviewState.loading(bag: bag),
    // الفشل لا يُحمل إلى كيسٍ جديد: الرسالة كانت عن ملفٍ لم يُقرأ، وتبديل المقاس ليس محاولةً
    // ثانية له — فتعود الشاشة إلى «ارفع تصميماً» بدل أن تبقى تحتها رسالةُ خطأ لا تخصّها.
    BagPreviewEmpty() || BagPreviewFailure() => BagPreviewState.empty(bag: bag),
  };

  /// نفس الحال بصورة كيسٍ وصلت (أو تعذّرت، فـ`null`).
  BagPreviewState withMockup(ui.Image? mockup) => switch (this) {
    BagPreviewReady(:final bag, :final design) => BagPreviewState.ready(
      bag: bag,
      design: design,
      mockup: mockup,
    ),
    BagPreviewLoading(:final bag) => BagPreviewState.loading(bag: bag, mockup: mockup),
    BagPreviewFailure(:final bag, :final failure) => BagPreviewState.failure(
      bag: bag,
      failure: failure,
      mockup: mockup,
    ),
    BagPreviewEmpty(:final bag) => BagPreviewState.empty(bag: bag, mockup: mockup),
  };
}
