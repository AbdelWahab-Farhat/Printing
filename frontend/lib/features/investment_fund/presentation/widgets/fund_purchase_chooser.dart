import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رفٌّ معروضٌ على الصندوق: اسمُه، وتكلفتُه الواصلة كما ستخرج من الخزينة، وبأيّ شيءٍ يُعدّ.
///
/// [unitWire] قيمةُ الخادم نفسُها (`kilogram` / `piece`) — عليها يقوم سريانُ الافتراض؛
/// و[per] «للكجم» كما تُقرأ بعد الرقم، وهي ما تحمله تسميةُ الحقل.
typedef FundShelf = ({
  int stockItemId,
  String title,
  String cost,
  String? unitWire,
  String per,
});

/// هل يسري سعرُ السادة الافتراضي على رفٍّ يُعدّ بهذه الوحدة؟
///
/// **الافتراضُ رقمٌ واحدٌ ووحدتُه الكيلو** — «حالياً في السادة نتعاملوا بالكيلو» — وفي الرفوف
/// ما يُعدّ بالقطعة. فـ٣٢ د.ل تُملأ في حقل رفٍّ يُباع بالقطعة رقمٌ خاطئ يُكتب في صمت، وحقلٌ
/// فارغٌ تسميتُه تقول وحدتَه أصدقُ منه.
bool fundDefaultFits(String? unitWire) => unitWire == StockUnit.kilogram.wire;

/// يملأ ما لم يُكتب بعدُ بالافتراض — ولرفوف الكيلو وحدها.
///
/// **لا يدوس على ما كُتب**: من كتب سعراً ثم أطفأ صفَّ التمويل وأعاده يجد رقمَه مكانه. ويُقصّ
/// الحشوُ العشري لأن الخادم يخزّن مالاً بثلاث خانات ومن يقرأ مربعاً يريد «32».
void seedFundPrices({
  required String? fallback,
  required List<FundShelf> shelves,
  required Map<int, TextEditingController> prices,
}) {
  if (fallback == null || fallback.trim().isEmpty) return;

  final value = trimDecimals(fallback.trim());

  for (final shelf in shelves) {
    final box = prices[shelf.stockItemId];

    if (box == null || box.text.isNotEmpty) continue;
    if (!fundDefaultFits(shelf.unitWire)) continue;

    box.text = value;
  }
}

/// أسعارُ السادة المكتوبةُ فعلاً، للرفوف المختارة وحدها.
///
/// **والفارغُ لا مفتاحَ له أصلاً**: يقرؤه الخادمُ «لا سعر» لا «صفر»، والصفرُ يسلّم المطبعةَ
/// البضاعةَ بلا ثمن. ورفٌّ رُفع عنه الصحُّ بعد أن كُتب سعرُه لا يُرسَل سعرُه معه — الحقلُ يبقى
/// ليعود إن عاد، ولا يصل إلى الخادم شيءٌ عن رفٍّ لا يشتريه الصندوق.
Map<int, String> fundPricesFrom(
  Map<int, TextEditingController> prices,
  Set<int> chosen,
) {
  final written = <int, String>{};

  for (final stockItemId in chosen) {
    final typed = Validators.toWesternDigits(
      prices[stockItemId]?.text ?? '',
    ).replaceAll(',', '.').trim();

    if (typed.isNotEmpty) written[stockItemId] = typed;
  }

  return written;
}

/// أنقدُ الصندوق أقلُّ ممّا اختير؟ — القاعدةُ الواحدة، تقرؤها الشاشةُ والحارسُ معاً.
///
/// **دالّةٌ حرّة لا خاصيّةٌ على الودجة**، لأن لها قارئين لا واحداً: الودجةُ ترسم بها الشريطَ
/// الأحمر، والنموذجُ يمنع بها الحفظ. ونسختان منها تعنيان شاشةً تقول «لا يكفي» وزرّاً يحفظ
/// رغم ذلك — وهي الحالُ التي رفضها المالك: «امنعه أصلاً وليس تحذيراً».
///
/// **و`null` ليست صفراً**: قراءةٌ لم تصل بعد لا تُقال «لا يكفي» ولا تمنع أحداً من الحفظ —
/// فمن في درجه المال لا تُقفَل الشاشةُ في وجهه لأن نداءً تأخّر. والسقفُ الحقيقيّ عند الخادم
/// لحظةَ الشراء، يسمّي الرقمين في رفضه.
bool fundCannotCover({required String? cash, required String cost}) {
  final held = cash;
  if (held == null) return false;

  return (double.tryParse(held) ?? 0) < (double.tryParse(cost) ?? 0);
}

/// **ما يسأله الصندوقُ قبل أن يشتري لورياً — سؤالان لا خمسة.**
///
/// أيَّ الرفوف يأخذ، وبكم تشتري المطبعةُ سادةَ كلٍّ منها. أمّا «من الممولون» و«كم وضع كلٌّ منهم»
/// و«بأيّ نسبٍ يُقسَّم» فماتت مع الصفقة: الصندوقُ يدفع الثمن كلَّه من خزينته، والنسبُ وحداتٌ
/// تُقرأ لكل فترة.
///
/// **وهو واحدٌ في شاشتين بحكم الضرورة لا بحكم الأناقة.** يُسأل السؤالُ نفسُه على تفصيل أمرٍ
/// قائم ({@link FundPurchasePage}) وعلى نموذج أمرٍ يُنشأ الآن — ونسختان منه تعنيان شاشةً تسأل
/// عن سعر السادة وأخرى نسيته، وهو سعرٌ **يُكتب هنا أو لا يُكتب أبداً**: يُجمَّد على السطر لحظةَ
/// المطالبة به، فلا شاشةَ ثانية تعدّله بعد أن تصير البضاعةُ طبقةَ تكلفة.
///
/// ولا يملك شيئاً مما يعرضه: المختارُ والحقولُ فوقه، عند من يملك دورةَ حياتها.
class FundPurchaseChooser extends StatelessWidget {
  const FundPurchaseChooser({
    required this.cash,
    required this.cost,
    required this.shelves,
    required this.chosen,
    required this.prices,
    required this.onToggle,
    super.key,
  });

  /// نقدُ الصندوق كما أرسله الخادم — **هو السقف، لا قيمةُ الصندوق**: صندوقٌ يساوي مئةَ ألفٍ قد
  /// لا يملك في درجه عشرة، والباقي بضاعةٌ ومستحقّات.
  ///
  /// **وnull يعني «لم يصل بعد» لا «صفر»**: سطرُ النقد يغيب وتغيب معه جملةُ «لا يكفي»، فقراءةٌ
  /// سقطت لا تُقال حمراءَ على شاشةِ من في درجه المال. والسقفُ الحقيقيّ يفرضه الخادمُ لحظةَ
  /// الشراء ويسمّي الرقمين في رفضه.
  final String? cash;

  /// تكلفةُ ما اختير، بالتكلفة الواصلة — وهي نفسُها ما سيخرج من الخزينة.
  final String cost;

  final List<FundShelf> shelves;
  final Set<int> chosen;

  /// حقلُ سعر السادة لكل رفّ. يملكها من يبني الشاشة، لأنها تُنشأ وتُتلف معها.
  final Map<int, TextEditingController> prices;

  final void Function(int stockItemId, bool chosen) onToggle;

  bool get _short => fundCannotCover(cash: cash, cost: cost);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cash case final held?) _Figure(label: 'نقد الصندوق', amount: held),
        _Figure(label: 'تكلفة ما اخترت', amount: cost, emphasis: true),
        if (_short) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'نقد الصندوق لا يكفي — الباقي بضاعةٌ ومستحقّاتٌ لم تُحصَّل',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
        SizedBox(height: 20.h),
        Text(
          'الرفوف',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        for (final shelf in shelves) ...[
          CheckboxListTile(
            value: chosen.contains(shelf.stockItemId),
            title: Text(shelf.title),
            subtitle: Text(
              '${shelf.cost.grouped} د.ل',
              textDirection: TextDirection.ltr,
            ),
            contentPadding: EdgeInsets.zero,
            onChanged: (checked) =>
                onToggle(shelf.stockItemId, checked ?? false),
          ),
          // الحقلُ تحت رفِّه لا في شاشةٍ ثانية: السعرُ يخصّ هذا الرفَّ وحده، ومن يكتبه يحتاج أن
          // يرى تكلفتَه فوقه — فالبيعُ بأقلّ منها خسارةٌ يكتبها بيده.
          if (chosen.contains(shelf.stockItemId))
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: AppTextField(
                controller: prices[shelf.stockItemId],
                // «اختياري» في العنوان لا في سطرٍ تحته: المتروكُ فارغاً يمشي على الطريق القديم
                // — يركب البيعَ إلى التسليم — وذاك ما يقوله الخادمُ حين يُسأل. والوحدةُ في
                // التسمية لأن الرقمَ يُضرب في كمية الرفّ بوحدته هو: «للكجم» أو «للقطعة».
                label: 'سعر السادة ${shelf.per} (د.ل، اختياري)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// سطرُ رقمٍ في رأس الورقة: ما هو، وكم.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    this.emphasis = false,
  });

  final String label;
  final String amount;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
