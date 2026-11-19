import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How the order's total was reached.
///
/// **Every number is rendered as the string the server sent.** Not parsed, not re-formatted: a
/// total assembled on the server and then re-derived on the phone is two answers to one
/// question, and the phone's is the one made of doubles.
///
/// Lines that are zero are absent rather than shown as `0.00` — a design fee of nothing is not
/// a fact about this order, it is the absence of one, and printing it invites the reader to
/// wonder what it means.
///
/// **«التوصيل» is under the total, not above it, and adds to nothing.** By the owner's
/// instruction the fee is not our revenue: the courier collects it from the customer at their
/// door, so «الإجمالي» is the goods and our own charges alone. **When we pay it** (DELIVERY-PAYER)
/// it is our cost instead, and appears a second time, as a subtraction on the way to the profit. It is still
/// printed, because a clerk quoting an order has to say what the trip costs — and printed
/// *below* the rule, because a figure standing above a total is a figure the reader adds into
/// it.
///
/// **والتكلفة والربح في العمود نفسه، لا في بطاقةٍ ثانية.** كانا لوحةً مستقلّة عنوانها «التكلفة
/// والربح»، فوقع الرقمان اللذان تُطرح أحدهما من الآخر في مكانين بينهما عنوانٌ جديد وحافّتان —
/// و«مجمل الربح = الإجمالي − تكلفة الإنتاج» هي الرابطة الوحيدة بينهما، ولم يكن على الشاشة ما
/// يقولها. الفصل كان فصل **جمهور** لا فصل معنى: التكلفة خلف `orders.view_cost`. فبقي الفصل
/// حيث ينفع — [showCosts] يقطع البطاقة عند «الإجمالي» لمن لا يملك الإذن — وذهب حيث لم ينفع.
///
/// **والعلامتان `−` و`=` مكتوبتان.** الخطّ الفاصل يقول «انتهى شيء» ولا يقول ماذا فُعل؛ والسؤال
/// الذي تجيبه هذه البطاقة هو «الرقم ده من وين جا».
class OrderTotals extends StatelessWidget {
  const OrderTotals({
    required this.order,
    this.showCosts = false,
    this.onChangeDeliveryPayer,
    this.onSetDesignFee,
    super.key,
  });

  final Order order;

  /// The pencil on «أجرة التصميم» — null unless the order still takes a fee and the reader holds
  /// `orders.design_fee`. See `Order.canSetDesignFee` and ORDER-DESIGN-FEE.md.
  final VoidCallback? onSetDesignFee;

  /// «تغيير» under the delivery line — null when the order may no longer change who pays, or
  /// the reader may not. See `Order.canChangeDeliveryPayer`.
  final VoidCallback? onChangeDeliveryPayer;

  /// Whether the two cost lines are drawn at all — `orders.view_cost`.
  ///
  /// **غيابٌ تام، لا تعطيل ولا «—».** من لا يملك الإذن يرى الحساب كما كان: بطاقةٌ تنتهي عند
  /// «الإجمالي». وسطرٌ رمادي مكانه إعلانٌ عن رقمٍ محجوب، وهو أسوأ من لا سطر.
  final bool showCosts;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        _Line(label: 'المنتجات', value: order.itemsTotal.grouped),
        // **Only for whoever holds `orders.design_fee`** — everybody else gets `'0.00'` and no
        // line, so the column above «الإجمالي» does not add up for them, by the owner's choice.
        // Drawn at zero too when it can be set: the line is where the pencil lives.
        if (order.hasDesignFee || onSetDesignFee != null)
          _Line(
            label: 'أجرة التصميم',
            note: order.designFeeIsAuto ? 'تلقائية' : null,
            value: order.designFee.grouped,
            onEdit: onSetDesignFee,
          ),
        // **Before the discount — the server's own order of operations.**
        // A reader checking the total works down the column, and a charge printed under the
        // subtraction it comes before turns a correct total into an arithmetic mistake.
        //
        // **What it was for is on the same line, not in a section under this one.** «كم» and
        // «على ماذا» are one fact about one charge; answering them in two places printed the
        // same figure twice, one card apart, and left the reader checking whether they matched.
        // The words are [Order.additionalCostCaption]'s — the same sentence the invoice and the
        // WhatsApp message carry, which is what stops one charge being described three ways.
        if (order.hasAdditionalCost)
          _Line(
            label: 'التكلفة الإضافية',
            note: order.additionalCostCaption,
            value: '+ ${order.additionalCost.grouped}',
          ),
        if (order.hasDiscount)
          _Line(label: 'الخصم', value: '- ${order.discount.grouped}', tone: scheme.error),
        // **«طلبية تعويض» — the whole of it comes off, as its own line.** The goods keep their
        // prices above so the reader sees what was given away; this line is why «الإجمالي»
        // below is 0.
        if (order.isCompensation)
          _Line(
            label: 'تعويض — بلا مقابل',
            note: order.compensationReasonLabel,
            value: '- ${_compensated(order)}',
            tone: scheme.error,
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
        _Line(label: 'الإجمالي', value: order.grandTotal.grouped, isTotal: true),
        if (showCosts) ...[
          SizedBox(height: 10.h),
          _Line(
            sign: '−',
            label: 'تكلفة الإنتاج',
            // **«لم يُحتسب بعد» وليس «٠».** لا تُكلَّف طلبيةٌ قبل «جاهزة» وخروج البضاعة من رفّ،
            // والصفر في تلك الفجوة يقول «هذه الطلبية لم تكلّفنا شيئاً» — وهي جملةٌ أخرى، وكاذبة.
            value: order.totalCogs?.grouped,
          ),
          // **When we pay the courier, the fee is the order's own cost** (option B) — a second
          // subtraction on the way to the profit, so «مجمل الربح» still adds up on the screen.
          if (order.wePayDelivery)
            _Line(sign: '−', label: 'التوصيل علينا', value: order.deliveryCost.grouped),
          // **والربح ينتظر التكلفة.** قبل «جاهزة» يكون «لم يُحتسب بعد» مرّتين، والثانية لا تقول
          // شيئاً لم تقله الأولى — فسطر `=` وخطّه لا يُرسمان حتى يوجد ما يُطرح.
          if (order.totalCogs != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              // أعرض من الخطّ فوق «الإجمالي»: حسبتان في عمودٍ واحد، والثانية هي التي تنتهي هنا.
              child: Divider(height: 1, thickness: 1.6, color: scheme.outlineVariant),
            ),
            _Line(
              sign: '=',
              label: 'مجمل الربح',
              value: order.grossProfit?.grouped,
              // الشيء الوحيد الذي يُقرأ من هذا السطر بلمحة: هل كسبت الطلبية أم خسرت. ملوَّنٌ حين
              // يكون الجواب «لا» وحدها — كلُّ طلبيةٍ رابحةٍ بالأخضر تجعل اللون بلا معنى عند
              // الثالثة.
              tone: _isLoss(order.grossProfit) ? scheme.error : null,
              isTotal: true,
            ),
          ],
        ],
        Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
          child: _Line(
            // The label carries the whole answer — who pays is why this figure is down here and
            // out of the sum, and a sentence under the line saying so would be the same fact
            // told twice.
            label: order.wePayDelivery ? 'التوصيل (علينا — مجاني للزبون)' : 'التوصيل (على الزبون)',
            // '0.00' is a fact worth stating — it is what an office pickup costs, and «كم
            // التوصيل؟» wants an answer rather than a missing line to infer one from. Only the
            // lines *inside* the total hide when empty.
            value: order.deliveryPrice.grouped,
          ),
        ),
        if (_nawrisDisagrees)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              order.wePayDelivery
                  ? 'نورس ما زالت تحمّل أجرتها على المستلم — لم يصلها التغيير، والمندوب سيطلبها منه.'
                  : 'نورس ما زالت تحمّل أجرتها علينا — لم يصلها التغيير، وستخصمها مما تحوّله.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        if (onChangeDeliveryPayer case final change?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: change,
              icon: Icon(AppIcons.edit, size: 16.sp),
              label: const Text('تغيير من يدفع التوصيل'),
            ),
          ),
      ],
    );
  }

  /// What a compensation order gives away — the lines and, when ours, the design.
  String _compensated(Order order) {
    final lines = num.tryParse(order.itemsTotal) ?? 0;
    final design = order.hasDesignFee ? (num.tryParse(order.designFee) ?? 0) : 0;

    return (lines + design).toStringAsFixed(2).grouped;
  }

  /// Nawris has the other side paying than the order says — our change never reached them.
  bool get _nawrisDisagrees {
    final parcel = order.nawrisParcel;
    final theirs = parcel?.nawrisPayer;

    return parcel != null && parcel.isOpen && theirs != null && theirs != order.deliveryPaidBy;
  }

  /// Whether the margin came out negative.
  ///
  /// `num.tryParse` for a comparison and for nothing else — what gets drawn is the string the
  /// server sent, `'-45.00'` and all. A parse on the way to the screen is how `'465.00'` becomes
  /// `465.00000000000006`.
  bool _isLoss(String? profit) => (num.tryParse(profit ?? '') ?? 0) < 0;
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.sign,
    this.note,
    this.tone,
    this.isTotal = false,
    this.onEdit,
  });

  final String label;

  /// Makes the whole line a tap target with a pencil beside the label — «أجرة التصميم» only.
  final VoidCallback? onEdit;

  /// The figure, or **null for one nobody has worked out yet** — drawn in words, never as zero.
  final String? value;

  /// `−` or `=`, drawn in its own column so the two line up under each other.
  ///
  /// Null on every line of the invoice itself: those are read down a column that has a rule
  /// under it, and a `+` on each would be four signs saying what one total already says.
  final String? sign;

  /// What this line was for, when the label alone does not say it — «نقل — سيارة أجرة».
  ///
  /// Null on every line whose label is the whole answer, which is all of them but the added
  /// charge: «المنتجات» needs no explaining and a note under it would be a sentence invented to
  /// fill a slot.
  final String? note;
  final Color? tone;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = isTotal
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : context.textTheme.bodyMedium;

    final line = Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          // عمودٌ ثابت العرض حتى لو لم تكن فيه علامة: `−` و`=` تقعان تحت بعضهما تماماً، والسطور
          // التي لا علامة لها تبدأ من حيث تبدأ الكلمات لا من حيث تبدأ العلامة.
          if (sign != null)
            SizedBox(
              width: 18.w,
              child: Text(
                sign!,
                // رقمٌ لاتيني وسط سطرٍ عربي: العلامة تُكتب كما كُتبت لا كما يقلبها الاتجاه.
                textDirection: TextDirection.ltr,
                style: style?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          // Expanded rather than a `Spacer` beside a bare label: the note is a clerk's own
          // sentence, so the label side has to be the part that gives way, and the number stays
          // where the column expects it however long the sentence runs.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: style?.copyWith(
                          color: isTotal ? null : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (onEdit != null) ...[
                      SizedBox(width: 6.w),
                      Icon(AppIcons.edit, size: 16.sp, color: scheme.primary),
                    ],
                  ],
                ),
                if (note case final note?)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      note,
                      // Two lines, because «أخرى» puts the clerk's own sentence here.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            // Grouped by the caller: «الخصم» carries a leading sign, and the separator is added
            // to the number rather than to the sentence around it.
            value ?? 'لم يُحتسب بعد',
            // A Latin run inside an RTL row, so the separator stays where it was written — and
            // the absence is a sentence, which reads right-to-left like the label beside it.
            textDirection: value == null ? null : TextDirection.ltr,
            style: value == null
                ? context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)
                : style?.copyWith(color: tone ?? (isTotal ? scheme.primary : null)),
          ),
        ],
      ),
    );

    return switch (onEdit) {
      final edit? => InkWell(onTap: edit, borderRadius: BorderRadius.circular(8.r), child: line),
      null => line,
    };
  }
}
