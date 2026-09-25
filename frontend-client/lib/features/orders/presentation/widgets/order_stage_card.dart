import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أعلى الطلبية المفتوحة: بطاقةٌ بلون المرحلة، فيها اسمها والخطوات الخمس وتاريخ كل خطوةٍ بلغتها.
///
/// **لون المرحلة نفسه الذي في «طلباتي»** (`stageTone`)، فلا يتبدّل لونها حين تُفتح. والبطاقة
/// لونٌ واحد: الخلفية ما يملأ شريط المرحلة هناك، وكل ما عليها — الاسم والنقاط والخطوط — بحبره.
///
/// **لا جملة تحت المرحلة.** كانت «نراجع طلبيتك ونؤكّدها…» (`stageHint`) تُكتب هنا، والخطوات
/// تقولها الآن: أين الطلبية، وما مضى، وما بقي. ويبقى سبب الرفض، فهو كلام المتجر عن هذه الطلبية
/// لا شرحٌ للمرحلة.
class OrderStageCard extends StatelessWidget {
  const OrderStageCard({required this.order, super.key});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = stageTone(scheme, order.stage);
    final marks = order.stage.marks;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(stageIcon(order.stage), size: 24.sp, color: tone.foreground),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  // كلمة الخادم كما هي، لا ترجمةٌ للقيمة.
                  order.stageLabel,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: tone.foreground,
                  ),
                ),
              ),
            ],
          ),

          if (marks != null) ...[
            SizedBox(height: 16.h),
            _Steps(marks: marks, reached: reachedSteps(order.timeline), tone: tone),
          ],

          if (order.rejectionReason case final reason?) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                reason,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// الخطوات الخمس في صفّ، بنقاطٍ يصلها خط: ممتلئةٌ بعلامةٍ لما مضى، وحلقةٌ لما الطلبية عليه،
/// وحلقةٌ باهتة لما أمامها. تحت كل خطوةٍ اسمها، وتحت ما بُلغ منها يومُ بلوغه.
///
/// **لا يتحرك** — كشريط الرئيسية: يُرسم حيث تقف الطلبية الآن. ولقارئ الشاشة جملةٌ واحدة
/// بدل عشر كلماتٍ متفرقة.
class _Steps extends StatelessWidget {
  const _Steps({required this.marks, required this.reached, required this.tone});

  final List<StepMark> marks;
  final Map<OrderStep, DateTime> reached;
  final ({Color background, Color foreground}) tone;

  @override
  Widget build(BuildContext context) {
    const steps = OrderStep.values;
    final current = marks.indexOf(StepMark.current);
    final lastReached = marks.lastIndexWhere((mark) => mark != StepMark.ahead);
    final quiet = _quietInk(context.colorScheme, tone);

    return Semantics(
      // عقدةٌ وحدها: بلا ذلك تندمج الجملة في عنوان البطاقة فوقها، فيُقرآن سطراً واحداً.
      container: true,
      label: current < 0
          ? 'اكتملت الخطوات الخمس'
          : 'الخطوة ${current + 1} من ${steps.length}: ${steps[current].label}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // الخط يبدأ من وسط أول عمودٍ وينتهي في وسط آخره، فيدخل النقاط لا يتجاوزها.
            final column = constraints.maxWidth / steps.length;
            final inset = column / 2;

            return Stack(
              children: [
                PositionedDirectional(
                  top: 10.w,
                  start: inset,
                  end: inset,
                  child: Container(height: 2.w, color: tone.foreground.withValues(alpha: 0.18)),
                ),
                if (lastReached > 0)
                  PositionedDirectional(
                    top: 10.w,
                    start: inset,
                    width: column * lastReached,
                    child: Container(height: 2.w, color: tone.foreground),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in steps)
                      Expanded(
                        child: _Step(
                          label: step.label,
                          mark: marks[step.index],
                          reachedAt: reached[step],
                          ink: tone.foreground,
                          quiet: quiet,
                          fill: tone.background,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// حبرٌ أخفت لما لم يُبلغ بعد ولتواريخ الخطوات، يبقى مقروءاً على لون المرحلة.
  ///
  /// **نهاراً حبر المرحلة نفسه ممزوجاً بخلفيتها** (٨٥٪) — قيس على الأربعة: البرتقالي والأزرق
  /// والرملي والأخضر، وكلها فوق ٤٫٥ إلى ١. **وليلاً نصّ الصفحة** ممزوجاً بها (٧٠٪): حبر المرحلة
  /// ليلاً مضيءٌ على خلفيةٍ داكنة، وتخفيفه نحوها ينزل به تحت ٤٫٥ إلى ١ على البرتقالي والأزرق.
  static Color _quietInk(ColorScheme scheme, ({Color background, Color foreground}) tone) =>
      scheme.brightness == Brightness.dark
      ? Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.7), tone.background)
      : Color.alphaBlend(tone.foreground.withValues(alpha: 0.85), tone.background);
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.mark,
    required this.reachedAt,
    required this.ink,
    required this.quiet,
    required this.fill,
  });

  final String label;
  final StepMark mark;
  final DateTime? reachedAt;
  final Color ink;
  final Color quiet;

  /// لون البطاقة، يملأ حلقة الخطوة التي أمام الطلبية فلا يمرّ الخط من داخلها.
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodySmall?.copyWith(fontSize: 12.5.sp, height: 1.35);

    return Column(
      children: [
        _Dot(mark: mark, ink: ink, fill: fill),
        SizedBox(height: 7.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(
            fontWeight: switch (mark) {
              StepMark.current => FontWeight.w800,
              StepMark.done => FontWeight.w700,
              StepMark.ahead => FontWeight.w600,
            },
            color: mark == StepMark.ahead ? quiet : ink,
          ),
        ),
        // يوم بلوغها وحده — السنة تسقط حين تكون هذه السنة، والساعة لا تتسع لها خمس خانات.
        if (reachedAt case final at? when mark != StepMark.ahead) ...[
          SizedBox(height: 1.h),
          Text(
            at.shortDayLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: style?.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: quiet),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.mark, required this.ink, required this.fill});

  final StepMark mark;
  final Color ink;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final size = 22.w;

    return switch (mark) {
      StepMark.done => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
        child: Icon(AppIcons.check, size: 13.sp, color: fill),
      ),

      // **حلقةٌ بنقطةٍ في وسطها: «هنا»**، لا دائرةٌ ممتلئة — تلك «تمّت».
      StepMark.current => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 3.w),
        ),
        child: Center(
          child: Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
        ),
      ),

      StepMark.ahead => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: ink.withValues(alpha: 0.22), width: 2.w),
        ),
      ),
    };
  }
}
