import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_settings.freezed.dart';
part 'investment_settings.g.dart';

/// القواعد التي يحكم بها الصندوقُ نفسَه — أربعُ مددٍ ونسبة.
///
/// **تغييرُها يسري على ما يُفتح بعدها ولا يمسّ فترةً قائمة.** الخادم ينسخ هذه القيم على صفّ
/// الفترة يوم يُنشئه ولا يقرأها من هنا بعدها، فمن أُقفل على شهرٍ واحد يبقى شهراً واحداً ولو
/// صارت المدةُ شهرين غداً. الشاشةُ تقول ذلك بصوتٍ عالٍ لأن من يعدّل رقماً هنا يظنّ — بحقّ — أنه
/// قد يحرّك تاريخاً.
///
/// [periodMonths] و[settlementMonths] **مرتبطان**: الثانيةُ يجب أن تكون مضاعفاً صحيحاً للأولى،
/// وإلا قُطعت فترةٌ في منتصفها فقُوِّمت بضاعةٌ لم يُغلق حسابُها. الخادم يرفضها برسالةٍ عربية،
/// والقاعدةُ ترفضها خلفه مهما كان الطريق.
@freezed
abstract class InvestmentSettings with _$InvestmentSettings {
  const factory InvestmentSettings({
    /// حصة المستثمرين من ربح الفترة — والباقي للشركة.
    @JsonKey(name: 'investor_profit_share_percent')
    required String investorProfitSharePercent,

    /// كم شهراً تدوم الفترة المحاسبية — وعليها يقع إقفال الأرباح.
    @JsonKey(name: 'investment_period_months') required int periodMonths,

    /// أوّلُ الفترة الذي يُقبَل فيه إيداعُ رأس مال. ما يصل بعده يُحتجز ولا يُنفَق.
    @JsonKey(name: 'investment_subscription_window_days')
    required int subscriptionWindowDays,

    /// دورةُ المراجعة الشاملة — أطول من دورة الأرباح ومستقلّةٌ عنها.
    @JsonKey(name: 'investment_settlement_months') required int settlementMonths,

    /// **سعرُ السادة الافتراضي — بالكيلو.** ما تُملأ به حقولُ التمويل قبل أن يُكتب رقم، فيُرى
    /// ويُغيَّر لكل رفّ؛ والمكتوبُ وحده يُجمَّد على سطر التوريد. null يعني «لا افتراض»: تُفتح
    /// الحقولُ فارغةً فتمشي البضاعةُ إلى المطبعة بالتكلفة.
    ///
    /// **ووحدتُه الكيلو**، لأن السادة تُشترى بالوزن اليوم — فلا يُملأ به رفٌّ يُعدّ بالقطعة.
    @JsonKey(name: 'default_plain_sale_price') String? defaultPlainSalePrice,

    /// كم يبقى رأسُ المال محجوزاً بعد إيداعه. **ولكلّ إيداعٍ ساعتُه**: من أودع في يناير وأودع
    /// ثانيةً في يونيو يُفكّ الأول قبل الثاني بخمسة أشهر.
    @JsonKey(name: 'investment_capital_lock_months') required int capitalLockMonths,
  }) = _InvestmentSettings;

  factory InvestmentSettings.fromJson(Map<String, dynamic> json) =>
      _$InvestmentSettingsFromJson(json);
}
