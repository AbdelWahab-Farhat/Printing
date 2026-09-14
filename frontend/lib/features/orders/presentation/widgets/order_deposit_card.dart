import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «العربون» — ما اتُّفق عليه في سطر، وتأكيد وصوله في مفتاح تحته.
///
/// **ثلاث وقائع لا واحدة.** ما طُلب من الزبون شيء، وقولُ موظفٍ إنّه دُفع شيءٌ ثانٍ، ورؤية المال
/// شيءٌ ثالث. العنوان يقول الأولى، والمفتاح يسجّل الثالثة، والثانية هي الحالة التي مرّت بها
/// الطلبية في طريقها إلى هنا. و«العربون ٢٥٠» أعلى البطاقة ليس مالاً تحرّك: المال المُستلَم
/// يُقرأ في «المدفوع» مع بقيّة الحساب، وخلطُهما يجعل الطلبية تبدو مدفوعةً مرّتين.
///
/// **وتُرسم على وجود العربون لا على حالة الطلبية.** العربون يُؤكَّد بعد أن تمضي الطلبية بوقتٍ
/// طويل — بعد شحنها أحياناً — فالسؤال «هل كان على هذه الطلبية عربون؟» لا «أين هي الآن؟». ربطُها
/// بالحالة كان يُخفي البطاقة عن المحاسب في اللحظة التي يفتحها لأجلها.
///
/// **والمفتاح مقفولٌ على [Order.canConfirmDeposit] وحدها.** الخادم يطوي فيها أمرين: المنحة،
/// وقاعدة أنّ من نقل الطلبية إلى «عربون مدفوع» لا يؤكّد عربونها بنفسه. الثاني سؤالٌ لا يملك
/// التطبيق جوابه — في صفّ القائمة لا يصل `deposit_claimed_by` أصلاً — فاشتقاقه هنا رأيٌ ثانٍ
/// يخطئ. ولا تختفي البطاقة عند من لا يملك المنحة، على قاعدة «الاستعجال» نفسها: «ليس لك» و«غير
/// موجود» يجب ألّا يتشابها.
///
/// **وتحت المفتاح المقفل سببه، وهو ليس سطر شرح.** مفتاحٌ رماديٌّ تحته فراغ يُقرأ كشاشةٍ معطوبة،
/// وهذه القاعدة بالذات لا يخمّنها من يقف أمامها: أن يكون المؤكِّد شخصاً آخر هو الغرض من الخانة
/// كلّها.
///
/// **والتناقض يُعرض ولا يُمنع.** الضغطة قولُ إنسان، والدفتر حساب؛ فحين يقول أحدهم «وصل العربون»
/// ولا دفعة على الطلبية، يُكتب ذلك بالأحمر ويُترك للمحاسب — تماماً كـ«الطلبية منتهية ولم يُسجَّل
/// قبض». ولا يُقفل المفتاح لأجله: منعُ التسجيل لا يجعل المال يصل.
class OrderDepositCard extends StatelessWidget {
  const OrderDepositCard({
    required this.order,
    required this.onChanged,
    this.claimedByMe = false,
    super.key,
  });

  final Order order;

  /// Null when the tick may not be moved. **Decided from [Order.canConfirmDeposit]**, never from
  /// the permission on its own — see the class note.
  final ValueChanged<bool>? onChanged;

  /// Whether the reader is the one who claimed the deposit was paid.
  ///
  /// Only ever used to choose *which sentence* sits under a locked switch; it never decides
  /// whether the switch is locked. The order is the authority on that, and this is a name
  /// comparison that is simply unavailable on a payload without `deposit_claimed_by`.
  final bool claimedByMe;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEditable = onChanged != null;
    final received = order.isDepositReceived;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.awaitingDeposit, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _agreement(order),
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            value: received,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            // الأخضر نفسه الذي تلبسه «مدفوعة بالكامل» و«رسالة الجاهزية»: لونٌ واحد لمعنى
            // «انتهى هذا» في التطبيق كلّه.
            activeTrackColor: scheme.paid,
            title: Text(
              'تأكيد استلام العربون',
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                // الكلمة تخفت مع المفتاح، فلا يُقرأ الصفّ حيّاً وهو مقفل.
                color: isEditable ? null : scheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              _subtitle(order, isEditable: isEditable, claimedByMe: claimedByMe),
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          // الواقعة التي يرويها رقمان لا يتّفقان. بالأحمر لأنّها عملٌ ينتظر أحداً، وتحت المفتاح
          // لا فوقه: تُقرأ بعد أن يُقرأ ما تتحدّث عنه.
          if (received && order.hasNoRecordedPayment)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 4.h),
              child: Text(
                'أُكِّد استلام العربون ولم تُسجَّل دفعة عليه',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// «العربون 250 · كاش», or as much of it as the order carries.
  ///
  /// The method is the server's own Arabic, exactly as every other label on this screen is; the
  /// figure is grouped and trimmed like every other figure.
  static String _agreement(Order order) {
    final amount = order.depositExpectedAmount?.grouped;
    final method = order.depositExpectedMethodLabel;

    return switch ((amount, method)) {
      (final value?, final label?) => 'العربون $value · $label',
      (final value?, null) => 'العربون $value',
      _ => 'العربون',
    };
  }

  /// The one line under the switch — a different sentence in each of the four states.
  ///
  /// The day is [AppDates.stamp] rather than «منذ ساعتين», for the reason the ready-message row
  /// gives: this is read weeks later, when somebody is asking what happened to the money.
  static String _subtitle(Order order, {required bool isEditable, required bool claimedByMe}) {
    if (order.isDepositReceived) {
      final who = order.depositConfirmedBy?.name;
      final when = order.depositConfirmedAt?.stampLabel;

      return switch ((who, when)) {
        (final name?, final stamp?) => 'أكّده $name · $stamp',
        (final name?, null) => 'أكّده $name',
        (null, final stamp?) => 'أُكِّد · $stamp',
        _ => 'أُكِّد استلامه',
      };
    }

    if (isEditable) return 'لم يُؤكَّد استلامه بعد';

    // The rule nobody guesses, said only to the person it is about. Anybody else reading a
    // locked switch is simply not the one who confirms deposits, and «بانتظار التأكيد» is the
    // fact they came for.
    return claimedByMe
        ? 'يؤكّد استلامَ العربون موظفٌ غير مَن نقل الطلبية'
        : 'بانتظار التأكيد';
  }
}
